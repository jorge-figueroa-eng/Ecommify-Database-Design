-- Estrategia de mantenimiento propuesta

-- Diario: limpieza estadística y actualización de planner.
VACUUM (ANALYZE) orders;
VACUUM (ANALYZE) order_items;
VACUUM (ANALYZE) order_payments;

-- Semanal: refrescar vistas materializadas analíticas.
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_category_monthly;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_segments;

-- Mensual: crear partición nueva antes del inicio del mes.
-- Ejemplo:
-- CREATE TABLE orders_2026_07 PARTITION OF orders
-- FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
