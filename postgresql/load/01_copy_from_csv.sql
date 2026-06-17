-- 01_copy_from_csv.sql
-- Ajustar DATA_DIR a la ubicacion real de los CSV. En Supabase remoto normalmente se recomienda cargar con Python/Colab.
-- Ejemplo local psql:
-- \set DATA_DIR '/ruta/a/csv'

\copy customers(customer_id,customer_unique_id,customer_zip_code_prefix,customer_city,customer_state) FROM :'DATA_DIR'/olist_customers_dataset.csv WITH (FORMAT csv, HEADER true);
\copy geolocations(geolocation_zip_code_prefix,geolocation_lat,geolocation_lng,geolocation_city,geolocation_state) FROM :'DATA_DIR'/olist_geolocation_dataset.csv WITH (FORMAT csv, HEADER true);
\copy sellers(seller_id,seller_zip_code_prefix,seller_city,seller_state) FROM :'DATA_DIR'/olist_sellers_dataset.csv WITH (FORMAT csv, HEADER true);
\copy product_categories(product_category_name,product_category_name_english) FROM :'DATA_DIR'/product_category_name_translation.csv WITH (FORMAT csv, HEADER true);
\copy products(product_id,product_category_name,product_name_lenght,product_description_lenght,product_photos_qty,product_weight_g,product_length_cm,product_height_cm,product_width_cm) FROM :'DATA_DIR'/olist_products_dataset.csv WITH (FORMAT csv, HEADER true);
\copy orders(order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,order_delivered_customer_date,order_estimated_delivery_date) FROM :'DATA_DIR'/olist_orders_dataset.csv WITH (FORMAT csv, HEADER true);
\copy order_payments(order_id,payment_sequential,payment_type,payment_installments,payment_value) FROM :'DATA_DIR'/olist_order_payments_dataset.csv WITH (FORMAT csv, HEADER true);
\copy order_reviews(review_id,order_id,review_score,review_comment_title,review_comment_message,review_creation_date,review_answer_timestamp) FROM :'DATA_DIR'/olist_order_reviews_dataset.csv WITH (FORMAT csv, HEADER true);

INSERT INTO orders_part
SELECT order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at,
       order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, raw_payload
FROM orders
ON CONFLICT DO NOTHING;

ANALYZE;
