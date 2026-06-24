-- 00_cleanup.sql
-- Limpieza total de tablas, vistas materializadas y tipos de Ecommify.
DROP TABLE IF EXISTS outbox_events CASCADE;
DROP TABLE IF EXISTS product_promotions CASCADE;
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS orders_part CASCADE; -- en caso de que exista de ejecuciones previas
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS geo_locations CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

DROP TYPE IF EXISTS address_br CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;

DROP MATERIALIZED VIEW IF EXISTS mv_sales_by_category_monthly CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_customer_segments CASCADE;
