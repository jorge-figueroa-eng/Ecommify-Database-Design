-- =====================================================================
-- 01_critical_queries.sql
-- FASE 1 (item 1): catálogo de consultas OLTP CRÍTICAS de Ecommify.
--
-- Son las operaciones de alta frecuencia / baja latencia que la aplicación
-- ejecuta constantemente (páginas de producto y de cuenta, seguimiento de
-- pedido, panel del vendedor, workers de fulfillment y de outbox). Se eligen
-- por FRECUENCIA e IMPACTO en la experiencia transaccional, no por su peso
-- analítico (las consultas OLAP viven en vistas materializadas).
--
-- Este script captura el PLAN BASE (estado "antes") sobre el esquema sin
-- índices de optimización ni particionamiento. Ejecutar:
--   psql "$DB" -f sql/01_critical_queries.sql > results/01_baseline_plans.txt
--
-- Literales tomados de datos reales cargados (ver README).
-- =====================================================================
\timing off
\pset pager off

-- ---------------------------------------------------------------------
-- Q1 — Detalle de orden por order_id (página de pedido, email de
-- confirmación, soporte). La app suele conocer SÓLO order_id.
-- PROBLEMA: la PK es (order_id, order_purchase_timestamp); sin el timestamp
-- el prefijo de la PK no es utilizable -> Seq Scan sobre 1M de filas.
-- ---------------------------------------------------------------------
\echo '==== Q1: order detail by order_id (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE order_id = 'ae21dab13299b0e599f3e0256ddc246d';

-- ---------------------------------------------------------------------
-- Q2 — Historial de pedidos de una persona (página "mis pedidos"),
-- ordenado por recencia. La persona es customer_unique_id; las órdenes
-- referencian customer_id -> requiere join customers→orders.
-- ---------------------------------------------------------------------
\echo '==== Q2: customer order history by customer_unique_id (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_status, o.order_purchase_timestamp
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_unique_id = '699004a8a651aead4a580a420f615852'
ORDER BY o.order_purchase_timestamp DESC
LIMIT 20;

-- ---------------------------------------------------------------------
-- Q3 — Seguimiento de pedido por order_id ("rastrea tu pedido").
-- Muy alta frecuencia; sólo necesita unas pocas columnas de estado.
-- ---------------------------------------------------------------------
\echo '==== Q3: order tracking by order_id (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_status, order_delivered_customer_date, order_estimated_delivery_date
FROM orders
WHERE order_id = 'ae21dab13299b0e599f3e0256ddc246d';

-- ---------------------------------------------------------------------
-- Q4 — Ítems recientes de un vendedor (panel del vendedor), paginado.
-- ---------------------------------------------------------------------
\echo '==== Q4: seller recent items (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.order_id, oi.product_id, oi.price, o.order_status, o.order_purchase_timestamp
FROM order_items oi
JOIN orders o
  ON o.order_id = oi.order_id
 AND o.order_purchase_timestamp = oi.order_purchase_timestamp
WHERE oi.seller_id = 'e08596db1d8709660710d430f071d879'
ORDER BY o.order_purchase_timestamp DESC
LIMIT 50;

-- ---------------------------------------------------------------------
-- Q5 — Navegación de catálogo por categoría, paginación por keyset.
-- ---------------------------------------------------------------------
\echo '==== Q5: catalog browse by category (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_category_name, product_weight_g
FROM products
WHERE category_id = 66
ORDER BY product_id
LIMIT 24;

-- ---------------------------------------------------------------------
-- Q6 — Promociones activas de un producto (se evalúa en cada vista de
-- producto). Respaldada por el índice GiST de la restricción EXCLUDE.
-- ---------------------------------------------------------------------
\echo '==== Q6: active promotions for a product (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT promotion_id, discount_percentage
FROM product_promotions
WHERE product_id = '9dae42a71c8f392de3ced691d503ea60'
  AND promotion_period @> now();

-- ---------------------------------------------------------------------
-- Q7 — Pedidos por aprobar (worker de fulfillment). Predicado MUY
-- selectivo: order_status='created' (~0,5% de las filas).
-- ---------------------------------------------------------------------
\echo '==== Q7: orders awaiting approval (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_purchase_timestamp
FROM orders
WHERE order_status = 'created'
ORDER BY order_purchase_timestamp
LIMIT 100;

-- ---------------------------------------------------------------------
-- Q8 — Sondeo del despachador de outbox (patrón transactional outbox).
-- Predicado parcial: processed_at IS NULL (~2%).
-- ---------------------------------------------------------------------
\echo '==== Q8: outbox dispatcher poll (baseline) ===='
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, payload
FROM outbox_events
WHERE processed_at IS NULL
ORDER BY created_at
LIMIT 100;
