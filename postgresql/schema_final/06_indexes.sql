-- 06_indexes.sql
-- Índices especializados requeridos por la rúbrica.

-- B-tree: filtros por estado y fecha.
CREATE INDEX IF NOT EXISTS idx_orders_status_purchase
ON orders (order_status, order_purchase_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_orders_part_status_purchase
ON orders_part (order_status, order_purchase_timestamp DESC);

-- BRIN: rangos temporales grandes.
CREATE INDEX IF NOT EXISTS idx_orders_purchase_brin
ON orders USING BRIN (order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_part_purchase_brin
ON orders_part USING BRIN (order_purchase_timestamp);

-- B-tree compuesto para joins y agrupaciones.
CREATE INDEX IF NOT EXISTS idx_customers_id_state
ON customers (customer_id, customer_state);

CREATE INDEX IF NOT EXISTS idx_order_items_product_seller
ON order_items (product_id, seller_id);

CREATE INDEX IF NOT EXISTS idx_order_items_seller_price
ON order_items (seller_id, price DESC);

CREATE INDEX IF NOT EXISTS idx_order_payments_type_value
ON order_payments (payment_type, payment_value DESC);

-- GiST/PostGIS: consultas espaciales.
CREATE INDEX IF NOT EXISTS idx_geolocations_geom_gist
ON geolocations USING GIST (geom);

-- GIN + pg_trgm: búsquedas aproximadas de ciudad y comentarios.
CREATE INDEX IF NOT EXISTS idx_geolocations_city_trgm
ON geolocations USING GIN (geolocation_city gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_reviews_comment_trgm
ON order_reviews USING GIN (review_comment_message gin_trgm_ops);

-- GIN JSONB: consultas sobre metadata y atributos.
CREATE INDEX IF NOT EXISTS idx_products_attributes_gin
ON products USING GIN (attributes jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_products_metadata_gin
ON products USING GIN (metadata);

-- GIN arrays: etiquetas.
CREATE INDEX IF NOT EXISTS idx_customer_tags_gin
ON customers USING GIN (customer_tags);

CREATE INDEX IF NOT EXISTS idx_review_tags_gin
ON order_reviews USING GIN (review_tags);

-- Índice parcial: subconjunto crítico para entregas reales.
CREATE INDEX IF NOT EXISTS idx_orders_delivered_purchase_partial
ON orders (order_purchase_timestamp DESC, customer_id)
WHERE order_status = 'delivered';

-- Índice parcial: reseñas negativas con comentario.
CREATE INDEX IF NOT EXISTS idx_reviews_low_score_with_comment_partial
ON order_reviews (review_score, review_creation_date DESC)
WHERE review_score <= 3 AND review_comment_message IS NOT NULL;
