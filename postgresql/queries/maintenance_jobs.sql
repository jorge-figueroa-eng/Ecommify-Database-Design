-- maintenance_jobs.sql
-- Estrategia operativa sugerida para Supabase / PostgreSQL.

-- Diario:
VACUUM (ANALYZE) orders;
VACUUM (ANALYZE) order_items;
VACUUM (ANALYZE) order_payments;

-- Semanal:
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_category_monthly;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_segments;

-- Mensual:
-- Crear nueva particion de orders antes del inicio del mes siguiente.
-- Revisar crecimiento de indices y particiones historicas.

-- Indicadores de monitoreo:
-- latencia p95 de consultas por order_id
-- tasa de errores de integridad referencial
-- tiempo de refresh de materialized views
-- crecimiento de tablas y particiones
-- eventos pendientes en outbox_events
