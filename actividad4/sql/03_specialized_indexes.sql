-- =====================================================================
-- 03_specialized_indexes.sql
-- FASE 2 — Índices especializados.
--
-- Se implementan CINCO tipos de índice, cada uno elegido por el patrón de
-- consulta que optimiza (el enunciado pide >=3 tipos):
--
--   IDX-1  B-tree simple      -> customers(customer_unique_id) + orders(customer_id)   [Q2]
--   IDX-2  B-tree compuesto   -> order_items(seller_id, order_purchase_timestamp DESC) [Q4]
--   IDX-3  B-tree compuesto   -> products(category_id, product_id)                     [Q5]
--   IDX-4  Parcial            -> orders(order_purchase_timestamp) WHERE status='created'[Q7]
--   IDX-5  Parcial            -> outbox_events(created_at) WHERE processed_at IS NULL   [Q8]
--   IDX-6  GIN (jsonb_path_ops)-> products(product_specifications)                      [JSONB @>]
--   IDX-7  BRIN vs B-tree     -> comparación de tamaño/velocidad en rango temporal
--
-- Cada bloque captura el plan ANTES (sin índice), crea el índice, refresca
-- estadísticas y captura el plan DESPUÉS, más el TAMAÑO del índice.
--
-- Captura: psql "$DB" -f sql/03_specialized_indexes.sql > results/03_indexes.txt
-- =====================================================================
\timing off
\pset pager off

-- =====================================================================
-- IDX-1 — B-tree SIMPLE: historial de pedidos de una persona (Q2).
-- Patrón: filtro por customers.customer_unique_id + join orders.customer_id.
-- En el base ambos lados son Seq Scan. Dos B-tree simples resuelven el
-- filtro y el join.
-- =====================================================================
DROP INDEX IF EXISTS idx_customers_unique_id;
DROP INDEX IF EXISTS idx_orders_customer;

\echo '######## IDX-1 BEFORE (Q2 customer history) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_status, o.order_purchase_timestamp
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_unique_id = '699004a8a651aead4a580a420f615852'
ORDER BY o.order_purchase_timestamp DESC
LIMIT 20;

CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX idx_orders_customer     ON orders(customer_id);
ANALYZE customers; ANALYZE orders;

\echo '######## IDX-1 AFTER ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_status, o.order_purchase_timestamp
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_unique_id = '699004a8a651aead4a580a420f615852'
ORDER BY o.order_purchase_timestamp DESC
LIMIT 20;

\echo '---- IDX-1 sizes ----'
SELECT 'idx_customers_unique_id' idx, pg_size_pretty(pg_relation_size('idx_customers_unique_id')) size
UNION ALL SELECT 'idx_orders_customer', pg_size_pretty(pg_relation_size('idx_orders_customer'));

-- =====================================================================
-- IDX-2 — B-tree COMPUESTO: ítems recientes de un vendedor (Q4).
-- Patrón: WHERE seller_id = ? ORDER BY order_purchase_timestamp DESC LIMIT.
-- El orden de columnas (igualdad primero, orden después) permite servir el
-- filtro Y el ORDER BY desde el índice, evitando el Sort.
-- =====================================================================
DROP INDEX IF EXISTS idx_order_items_seller_ts;

\echo '######## IDX-2 BEFORE (Q4 seller items) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.order_id, oi.product_id, oi.price, o.order_status, o.order_purchase_timestamp
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id AND o.order_purchase_timestamp = oi.order_purchase_timestamp
WHERE oi.seller_id = 'e08596db1d8709660710d430f071d879'
ORDER BY o.order_purchase_timestamp DESC
LIMIT 50;

CREATE INDEX idx_order_items_seller_ts ON order_items(seller_id, order_purchase_timestamp DESC);
ANALYZE order_items;

\echo '######## IDX-2 AFTER ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.order_id, oi.product_id, oi.price, o.order_status, o.order_purchase_timestamp
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id AND o.order_purchase_timestamp = oi.order_purchase_timestamp
WHERE oi.seller_id = 'e08596db1d8709660710d430f071d879'
ORDER BY o.order_purchase_timestamp DESC
LIMIT 50;

\echo '---- IDX-2 size ----'
SELECT pg_size_pretty(pg_relation_size('idx_order_items_seller_ts')) AS idx_order_items_seller_ts;

-- =====================================================================
-- IDX-3 — B-tree COMPUESTO: navegación de catálogo por categoría (Q5).
-- Patrón: WHERE category_id = ? ORDER BY product_id LIMIT (keyset).
-- =====================================================================
DROP INDEX IF EXISTS idx_products_category_pid;

\echo '######## IDX-3 BEFORE (Q5 catalog browse) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_category_name, product_weight_g
FROM products WHERE category_id = 66 ORDER BY product_id LIMIT 24;

CREATE INDEX idx_products_category_pid ON products(category_id, product_id);
ANALYZE products;

\echo '######## IDX-3 AFTER ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_category_name, product_weight_g
FROM products WHERE category_id = 66 ORDER BY product_id LIMIT 24;

\echo '---- IDX-3 size ----'
SELECT pg_size_pretty(pg_relation_size('idx_products_category_pid')) AS idx_products_category_pid;

-- =====================================================================
-- IDX-4 — PARCIAL: pedidos por aprobar (Q7).
-- Patrón: WHERE order_status='created' (0,5%) ORDER BY purchase_ts.
-- El índice parcial sólo cubre las filas 'created' -> diminuto y muy
-- selectivo; sirve además el ORDER BY.
-- =====================================================================
DROP INDEX IF EXISTS idx_orders_created_pending;

\echo '######## IDX-4 BEFORE (Q7 awaiting approval) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_purchase_timestamp
FROM orders WHERE order_status = 'created'
ORDER BY order_purchase_timestamp LIMIT 100;

CREATE INDEX idx_orders_created_pending ON orders(order_purchase_timestamp)
    WHERE order_status = 'created';
ANALYZE orders;

\echo '######## IDX-4 AFTER ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_purchase_timestamp
FROM orders WHERE order_status = 'created'
ORDER BY order_purchase_timestamp LIMIT 100;

\echo '---- IDX-4 size (compare con un B-tree total sobre order_status) ----'
SELECT pg_size_pretty(pg_relation_size('idx_orders_created_pending')) AS idx_parcial;

-- =====================================================================
-- IDX-5 — PARCIAL: despachador de outbox (Q8). Es el índice del diseño
-- híbrido (idx_outbox_unprocessed): cubre sólo ~2% de filas pendientes.
-- =====================================================================
DROP INDEX IF EXISTS idx_outbox_unprocessed;

\echo '######## IDX-5 BEFORE (Q8 outbox poll) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, payload FROM outbox_events
WHERE processed_at IS NULL ORDER BY created_at LIMIT 100;

CREATE INDEX idx_outbox_unprocessed ON outbox_events(created_at)
    WHERE processed_at IS NULL;
ANALYZE outbox_events;

\echo '######## IDX-5 AFTER ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, payload FROM outbox_events
WHERE processed_at IS NULL ORDER BY created_at LIMIT 100;

\echo '---- IDX-5 size ----'
SELECT pg_size_pretty(pg_relation_size('idx_outbox_unprocessed')) AS idx_outbox_unprocessed;

-- =====================================================================
-- IDX-6 — GIN (jsonb_path_ops): búsqueda por contención en JSONB.
-- Patrón: product_specifications @> '{"warranty_months":24,"logistics":
-- {"fragile":true}}' (~2% = 637 de 32K). B-tree NO PUEDE indexar contención
-- JSONB; GIN sí. jsonb_path_ops es más compacto y rápido que el GIN por
-- defecto cuando sólo se usa @>.
-- SELECTIVIDAD = condición de éxito: con este predicado selectivo GIN gana
-- limpio. Con un predicado POCO selectivo sobre una tabla cache-resident la
-- ventaja se evapora (ver nota de trade-off en REPORTE.md §3.2 IDX-6).
-- =====================================================================
DROP INDEX IF EXISTS idx_products_specs_gin;

\echo '######## IDX-6 BEFORE (JSONB containment, selective) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id
FROM products
WHERE product_specifications @> '{"warranty_months":24,"logistics":{"fragile":true}}';

CREATE INDEX idx_products_specs_gin ON products
    USING gin (product_specifications jsonb_path_ops);
ANALYZE products;

\echo '######## IDX-6 AFTER ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id
FROM products
WHERE product_specifications @> '{"warranty_months":24,"logistics":{"fragile":true}}';

\echo '---- IDX-6 size ----'
SELECT pg_size_pretty(pg_relation_size('idx_products_specs_gin')) AS idx_products_specs_gin;

-- =====================================================================
-- IDX-7 — BRIN vs B-tree sobre rango temporal.
-- BRIN sólo es efectivo si el orden FÍSICO correlaciona con la columna. Una
-- tabla orders de producción es append-only -> llega ordenada por tiempo. El
-- generador sintético barajó los timestamps, así que materializamos una copia
-- ORDENADA que emula esa correlación natural y comparamos B-tree vs BRIN.
-- =====================================================================
DROP TABLE IF EXISTS orders_ts_demo;
CREATE TABLE orders_ts_demo AS
SELECT order_id, order_purchase_timestamp, order_status
FROM orders ORDER BY order_purchase_timestamp;   -- correlación física alta
ANALYZE orders_ts_demo;

\echo '######## IDX-7 BEFORE (range scan, sin índice) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM orders_ts_demo
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2017-06-01'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2017-07-01';

-- B-tree (rápido, pero grande)
CREATE INDEX idx_demo_btree ON orders_ts_demo(order_purchase_timestamp);
ANALYZE orders_ts_demo;
\echo '######## IDX-7 AFTER (B-tree) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM orders_ts_demo
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2017-06-01'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2017-07-01';

-- BRIN (diminuto; aprovecha la correlación física)
DROP INDEX idx_demo_btree;
CREATE INDEX idx_demo_brin ON orders_ts_demo
    USING brin (order_purchase_timestamp) WITH (pages_per_range = 32);
ANALYZE orders_ts_demo;
\echo '######## IDX-7 AFTER (BRIN) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM orders_ts_demo
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2017-06-01'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2017-07-01';

\echo '---- IDX-7 tamaños: B-tree vs BRIN ----'
CREATE INDEX idx_demo_btree2 ON orders_ts_demo(order_purchase_timestamp);
SELECT 'B-tree' tipo, pg_size_pretty(pg_relation_size('idx_demo_btree2')) size
UNION ALL
SELECT 'BRIN',   pg_size_pretty(pg_relation_size('idx_demo_brin'));
