-- =====================================================================
-- 02_query_optimizations.sql
-- FASE 1 (items 2-5): optimización por análisis de planes de ejecución.
--
-- Estas consultas son CRÍTICAS por TIEMPO DE RESPUESTA / IMPACTO (jobs de
-- conciliación, reportes operativos, dashboards y paginación de catálogo).
-- A diferencia de los accesos puntuales de 01_critical_queries.sql —cuyo
-- cuello de botella es el camino de acceso y se resuelven con ÍNDICES en la
-- Fase 2— aquí el cuello de botella es la ESTRUCTURA del SQL, por lo que la
-- mejora se logra REESCRIBIENDO la consulta (sin agregar índices).
--
-- Se aplican 4 técnicas (el enunciado pide >=3):
--   OPT-1  Descorrelación: subconsulta correlacionada -> JOIN + GROUP BY
--   OPT-2  Sargabilidad: eliminar función sobre la columna en WHERE
--   OPT-3  Anti-join: NOT IN (subquery) -> NOT EXISTS
--   OPT-4  Paginación: OFFSET profundo -> keyset (seek method)
--
-- Captura: psql "$DB" -f sql/02_query_optimizations.sql > results/02_optimizations.txt
-- Medido sobre el esquema BASE (sin índices de optimización) para aislar el
-- efecto de la reescritura.
-- =====================================================================
\timing off
\pset pager off

-- =====================================================================
-- OPT-1 — Descorrelación de subconsultas escalares.
-- Caso: reporte "ventas por vendedor" para una página de 100 vendedores.
-- La versión naíf (estilo ORM) ejecuta DOS subconsultas correlacionadas por
-- cada vendedor; como order_items no tiene índice por seller_id, cada una
-- hace un Seq Scan de 1,5M filas -> 100 x 2 recorridos completos.
-- La reescritura agrupa en UN solo recorrido con JOIN + GROUP BY.
-- =====================================================================
\echo '######## OPT-1 BEFORE: correlated scalar subqueries ########'
EXPLAIN (ANALYZE, BUFFERS)
WITH s100 AS MATERIALIZED (
    SELECT seller_id FROM sellers ORDER BY seller_id LIMIT 100
)
SELECT s.seller_id,
       (SELECT count(*)             FROM order_items i WHERE i.seller_id = s.seller_id) AS items_sold,
       (SELECT coalesce(sum(i.price),0) FROM order_items i WHERE i.seller_id = s.seller_id) AS revenue
FROM s100 s;

\echo '######## OPT-1 AFTER: single JOIN + GROUP BY ########'
EXPLAIN (ANALYZE, BUFFERS)
WITH s100 AS MATERIALIZED (
    SELECT seller_id FROM sellers ORDER BY seller_id LIMIT 100
)
SELECT s.seller_id,
       count(i.*)                   AS items_sold,
       coalesce(sum(i.price),0)     AS revenue
FROM s100 s
LEFT JOIN order_items i ON i.seller_id = s.seller_id
GROUP BY s.seller_id;

-- =====================================================================
-- OPT-2 — Sargabilidad: quitar la función sobre la columna filtrada.
-- Caso: reporte de estados de un día concreto.
-- date_trunc('day', col) = '...' obliga a evaluar la función en cada fila y,
-- lo más importante, vuelve el predicado NO-SARGABLE (no puede usar índice ni
-- poda de particiones). La forma equivalente con rango semiabierto sí es
-- sargable (clave para la Fase 2 y la Fase 3).
-- =====================================================================
\echo '######## OPT-2 BEFORE: function on column (date_trunc) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_status, count(*)
FROM orders
WHERE date_trunc('day', order_purchase_timestamp) = TIMESTAMPTZ '2018-05-10'
GROUP BY order_status;

\echo '######## OPT-2 AFTER: sargable half-open range ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_status, count(*)
FROM orders
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2018-05-10'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2018-05-11'
GROUP BY order_status;

-- =====================================================================
-- OPT-3 — Anti-join: NOT IN (subquery) -> NOT EXISTS.
-- Caso: job de CSAT que busca pedidos entregados (de un día) sin reseña.
-- NOT IN no puede convertirse en un anti-join hash limpio (semántica con
-- NULL) y degenera en un SubPlan re-evaluado; NOT EXISTS permite un Hash
-- Anti Join. Además NOT EXISTS es semánticamente correcto ante NULLs.
-- =====================================================================
\echo '######## OPT-3 BEFORE: NOT IN (subquery) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMPTZ '2018-05-10'
  AND o.order_purchase_timestamp <  TIMESTAMPTZ '2018-05-11'
  AND o.order_id NOT IN (SELECT order_id FROM order_reviews);

\echo '######## OPT-3 AFTER: NOT EXISTS (anti-join) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMPTZ '2018-05-10'
  AND o.order_purchase_timestamp <  TIMESTAMPTZ '2018-05-11'
  AND NOT EXISTS (SELECT 1 FROM order_reviews r WHERE r.order_id = o.order_id);

-- =====================================================================
-- OPT-4 — Paginación: OFFSET profundo -> keyset (seek method).
-- Caso: navegar a una página profunda del catálogo. OFFSET 20000 obliga a
-- recorrer y DESCARTAR 20.000 filas antes de devolver 24. El método keyset
-- arranca directamente en el cursor (último product_id de la página previa)
-- usando el índice de PK. No requiere índices nuevos.
-- =====================================================================
-- Cursor = product_id en la posición 5000 (simula "última fila de la página anterior").
SELECT product_id AS cursor FROM products ORDER BY product_id OFFSET 5000 LIMIT 1 \gset

\echo '######## OPT-4 BEFORE: deep OFFSET ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_category_name
FROM products
ORDER BY product_id
OFFSET 5000 LIMIT 24;

\echo '######## OPT-4 AFTER: keyset pagination ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_category_name
FROM products
WHERE product_id > :'cursor'
ORDER BY product_id
LIMIT 24;
