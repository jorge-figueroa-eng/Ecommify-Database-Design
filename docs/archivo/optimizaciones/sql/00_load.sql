-- =====================================================================
-- 00_load.sql
-- Carga masiva de los CSV sintéticos (generate_data.py) vía \copy.
-- Ejecutar con psql DESDE el directorio actividad4/:
--     psql "$DB_URL" -v ON_ERROR_STOP=1 -f sql/00_load.sql
-- Orden respetando llaves foráneas: dimensiones -> hechos.
-- =====================================================================
\set ON_ERROR_STOP on
\timing on

-- ---------- Dimensiones ----------
\copy geo_locations (zip_code_prefix, city, state, latitude, longitude) FROM 'data/geo_locations.csv' WITH (FORMAT csv, HEADER true)
\copy categories (category_id, name_pt, name_en) FROM 'data/categories.csv' WITH (FORMAT csv, HEADER true)
\copy sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state, capability_tags) FROM 'data/sellers.csv' WITH (FORMAT csv, HEADER true)
\copy products (product_id, category_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm, product_specifications, search_tokens) FROM 'data/products.csv' WITH (FORMAT csv, HEADER true)
\copy customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state) FROM 'data/customers.csv' WITH (FORMAT csv, HEADER true)

-- ---------- Hechos ----------
\copy orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, metadata) FROM 'data/orders.csv' WITH (FORMAT csv, HEADER true)
\copy order_items (order_id, order_purchase_timestamp, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value) FROM 'data/order_items.csv' WITH (FORMAT csv, HEADER true)
\copy order_payments (order_id, order_purchase_timestamp, payment_sequential, payment_type, payment_installments, payment_value) FROM 'data/order_payments.csv' WITH (FORMAT csv, HEADER true)
\copy order_reviews (review_id, order_id, order_purchase_timestamp, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp) FROM 'data/order_reviews.csv' WITH (FORMAT csv, HEADER true)
\copy product_promotions (product_id, seller_id, promotion_period, discount_percentage) FROM 'data/product_promotions.csv' WITH (FORMAT csv, HEADER true)
\copy outbox_events (aggregate_type, aggregate_id, event_type, payload, created_at, processed_at) FROM 'data/outbox_events.csv' WITH (FORMAT csv, HEADER true)

-- ---------- Post-procesamiento ----------
-- Alinear la secuencia de categories tras insertar category_id explícito.
SELECT setval(pg_get_serial_sequence('categories', 'category_id'),
              (SELECT max(category_id) FROM categories));

-- Derivar el punto geográfico (GEOGRAPHY) desde lat/lng para PostGIS.
UPDATE geo_locations
   SET geo_point = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
 WHERE longitude IS NOT NULL AND latitude IS NOT NULL;

-- Estadísticas frescas para que el planificador tome buenas decisiones.
VACUUM (ANALYZE);

-- ---------- Reporte de volúmenes ----------
SELECT relname AS tabla,
       to_char(n_live_tup, 'FM999,999,999') AS filas_aprox,
       pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
