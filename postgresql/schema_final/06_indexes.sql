-- 06_indexes.sql
-- Indices especializados requeridos: B-tree, GIN, GiST, BRIN, trigramas y parciales.

-- B-tree compuesto para consultas por estado/cliente y ordenamiento temporal.
CREATE INDEX IF NOT EXISTS idx_customers_state_city ON customers (customer_state, customer_city);
CREATE INDEX IF NOT EXISTS idx_orders_status_purchase ON orders (order_status, order_purchase_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_purchase ON orders (customer_id, order_purchase_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_payments_type_value ON order_payments (payment_type, payment_value DESC);

-- BRIN para rangos temporales grandes.
CREATE INDEX IF NOT EXISTS idx_orders_purchase_brin ON orders USING BRIN (order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_orders_part_purchase_brin ON orders_part USING BRIN (order_purchase_timestamp);

-- GiST/PostGIS para geolocalizacion.
CREATE INDEX IF NOT EXISTS idx_geolocations_geom ON geolocations USING GIST (geom);

-- GIN/pg_trgm para busquedas tolerantes.
CREATE INDEX IF NOT EXISTS idx_geolocations_city_trgm ON geolocations USING GIN (geolocation_city gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_reviews_comment_trgm ON order_reviews USING GIN (review_comment_message gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_category_trgm ON product_categories USING GIN (product_category_name_english gin_trgm_ops);

-- GIN para JSONB y arrays.
CREATE INDEX IF NOT EXISTS idx_products_specs_gin ON products USING GIN (specs);
CREATE INDEX IF NOT EXISTS idx_customers_tags_gin ON customers USING GIN (customer_tags);
CREATE INDEX IF NOT EXISTS idx_reviews_tags_gin ON order_reviews USING GIN (review_tags);

-- Indice parcial para subconjunto critico: ordenes entregadas.
CREATE INDEX IF NOT EXISTS idx_orders_delivered_purchase ON orders (order_purchase_timestamp DESC)
WHERE order_status = 'delivered';

-- Indice parcial para reviews negativas con comentario.
CREATE INDEX IF NOT EXISTS idx_reviews_low_score_comment ON order_reviews (review_score, review_creation_date DESC)
WHERE review_score <= 3 AND review_comment_message IS NOT NULL;
