-- 00_drop_all.sql
-- Limpieza segura para ambiente academico/desarrollo. No usar en produccion.
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_order_summary CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_payment_method_summary CASCADE;
DROP TABLE IF EXISTS outbox_events CASCADE;
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders_part CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS geolocations CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TYPE IF EXISTS order_status_enum CASCADE;
DROP TYPE IF EXISTS payment_type_enum CASCADE;
DROP TYPE IF EXISTS address_br CASCADE;
DROP DOMAIN IF EXISTS br_state CASCADE;
