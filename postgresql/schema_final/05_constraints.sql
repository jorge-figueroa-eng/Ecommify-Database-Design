-- 05_constraints.sql
-- Constraints e integridad adicional.

ALTER TABLE order_reviews
ADD CONSTRAINT IF NOT EXISTS chk_review_answer_after_creation
CHECK (review_answer_timestamp IS NULL OR review_creation_date IS NULL OR review_answer_timestamp >= review_creation_date);

ALTER TABLE order_items
ADD CONSTRAINT IF NOT EXISTS chk_order_item_id_positive
CHECK (order_item_id > 0);

ALTER TABLE order_payments
ADD CONSTRAINT IF NOT EXISTS chk_payment_sequential_positive
CHECK (payment_sequential > 0);

COMMENT ON TABLE customers IS 'Clientes normalizados del dataset Olist/Ecommify.';
COMMENT ON TABLE geolocations IS 'Geolocalización con columna PostGIS geography(Point,4326).';
COMMENT ON TABLE orders_part IS 'Tabla particionada por fecha de compra para análisis temporal.';
COMMENT ON TABLE outbox_events IS 'Transactional Outbox para sincronización eventual hacia MongoDB.';
