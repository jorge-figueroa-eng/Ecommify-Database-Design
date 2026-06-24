-- =====================================================================
-- 04_partitioning.sql
-- FASE 3 — Particionamiento declarativo.
--
-- ANÁLISIS Y SELECCIÓN
--   Tabla candidata: orders (1.000.000 filas > criterio de 100.000).
--   Columna de partición: order_purchase_timestamp. Es la columna que domina
--   los filtros WHERE de la carga (Q7, OPT-2, OPT-3, barridos por rango, demo
--   BRIN) y crece monótonamente (append-only).
--   Tipo: RANGE — el dato es temporal y las consultas son por rango de fechas
--   (no por valores discretos -> descarta LIST; no se busca distribución
--   uniforme -> descarta HASH).
--
-- DISEÑO DE ESTRATEGIA
--   Granularidad: MENSUAL (equilibra nº de particiones y tamaño de cada una;
--   ~38 K filas/mes). Partición DEFAULT como red de seguridad para datos
--   fuera de rango (las 1.000 filas anómalas de 2019 del generador).
--   Creación automática de particiones futuras: documentada al final.
--
-- IMPLEMENTACIÓN Y VALIDACIÓN
--   Se construye orders_part, se migran los datos y se compara el rendimiento
--   contra la tabla PLANA orders. Para aislar el efecto del PARTICIONAMIENTO,
--   ninguna de las dos tablas tiene índice sobre order_purchase_timestamp: así
--   la mejora proviene exclusivamente de la PODA de particiones.
--
-- Captura: psql "$DB" -f sql/04_partitioning.sql > results/04_partitioning.txt
-- =====================================================================
\timing off
\pset pager off

-- ---------- Tabla particionada ----------
DROP TABLE IF EXISTS orders_part CASCADE;
CREATE TABLE orders_part (
    order_id CHAR(32) NOT NULL,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(40) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_approved_at TIMESTAMPTZ,
    order_delivered_carrier_date TIMESTAMPTZ,
    order_delivered_customer_date TIMESTAMPTZ,
    order_estimated_delivery_date TIMESTAMPTZ NOT NULL,
    shipping_address_snapshot address_br,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    -- la clave de partición debe formar parte de la PK
    PRIMARY KEY (order_id, order_purchase_timestamp)
) PARTITION BY RANGE (order_purchase_timestamp);

-- ---------- Particiones mensuales 2016-09 .. 2018-10 ----------
DO $$
DECLARE
    m date := DATE '2016-09-01';
    hi date;
BEGIN
    WHILE m < DATE '2018-11-01' LOOP
        hi := (m + INTERVAL '1 month')::date;
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF orders_part FOR VALUES FROM (%L) TO (%L)',
            'orders_part_' || to_char(m, 'YYYY_MM'), m, hi);
        m := hi;
    END LOOP;
END $$;

-- ---------- Partición DEFAULT (red de seguridad) ----------
CREATE TABLE orders_part_default PARTITION OF orders_part DEFAULT;

-- ---------- Migración de datos existentes ----------
INSERT INTO orders_part (
    order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
    order_estimated_delivery_date, shipping_address_snapshot, metadata,
    created_at, updated_at)
SELECT
    order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
    order_estimated_delivery_date, shipping_address_snapshot, metadata,
    created_at, updated_at
FROM orders;

ANALYZE orders_part;

-- ---------- Validación estructural ----------
\echo '==== Particiones creadas y filas por partición (incluye DEFAULT) ===='
SELECT c.relname AS particion,
       to_char(c.reltuples::bigint, 'FM999,999,999') AS filas_aprox,
       pg_size_pretty(pg_relation_size(c.oid)) AS tamano
FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhrelid
WHERE i.inhparent = 'orders_part'::regclass
ORDER BY c.relname;

\echo '==== Filas que cayeron en la partición DEFAULT (anómalas 2019) ===='
SELECT count(*) AS filas_en_default FROM orders_part_default;

-- =====================================================================
-- COMPARACIÓN DE RENDIMIENTO: rango de un mes (con clave de partición)
-- =====================================================================
\echo '######## A) Barrido por rango — TABLA PLANA (orders) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(1) FROM orders
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2017-06-01'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2017-07-01';

\echo '######## B) Barrido por rango — TABLA PARTICIONADA (orders_part) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(1) FROM orders_part
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2017-06-01'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2017-07-01';

-- =====================================================================
-- TRADE-OFF: consulta SIN la clave de partición -> toca TODAS las particiones
-- (es el reverso del particionamiento; documenta la limitación honestamente).
-- =====================================================================
\echo '######## C) Consulta por order_id (sin clave de partición) ########'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_status FROM orders_part
WHERE order_id = 'ae21dab13299b0e599f3e0256ddc246d';

-- =====================================================================
-- ESTRATEGIA DE CREACIÓN AUTOMÁTICA DE PARTICIONES FUTURAS
-- ---------------------------------------------------------------------
-- Opción A (nativa): función que crea el mes siguiente, agendada con pg_cron:
--
--   CREATE OR REPLACE FUNCTION ensure_next_orders_partition()
--   RETURNS void LANGUAGE plpgsql AS $fn$
--   DECLARE lo date := date_trunc('month', now() + INTERVAL '1 month')::date;
--           hi date := (lo + INTERVAL '1 month')::date;
--           nm text := 'orders_part_' || to_char(lo,'YYYY_MM');
--   BEGIN
--     IF to_regclass(nm) IS NULL THEN
--       EXECUTE format('CREATE TABLE %I PARTITION OF orders_part FOR VALUES FROM (%L) TO (%L)', nm, lo, hi);
--     END IF;
--   END $fn$;
--   -- SELECT cron.schedule('orders-next-part','0 0 25 * *','SELECT ensure_next_orders_partition()');
--
-- Opción B (extensión): pg_partman con retención automática (p. ej. detach de
-- particiones > 24 meses). La partición DEFAULT queda como red de seguridad
-- ante datos fuera de rango (se monitorea que permanezca casi vacía).
-- =====================================================================
