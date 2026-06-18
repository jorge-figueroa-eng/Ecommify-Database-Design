-- copy_commands.sql
-- Ajustar rutas según el entorno. En Supabase puede usarse importador CSV o psql local con \copy.

-- Ejemplo local con psql:
-- \copy customers(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state) FROM 'data/raw/olist_customers_dataset.csv' CSV HEADER;
-- \copy sellers(seller_id, seller_zip_code_prefix, seller_city, seller_state) FROM 'data/raw/olist_sellers_dataset.csv' CSV HEADER;
-- \copy product_categories(product_category_name, product_category_name_english) FROM 'data/raw/product_category_name_translation.csv' CSV HEADER;
-- \copy products(product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm) FROM 'data/raw/olist_products_dataset.csv' CSV HEADER;
-- \copy orders(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date) FROM 'data/raw/olist_orders_dataset.csv' CSV HEADER;
-- \copy order_payments(order_id, payment_sequential, payment_type, payment_installments, payment_value) FROM 'data/raw/olist_order_payments_dataset.csv' CSV HEADER;
-- \copy order_reviews(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp) FROM 'data/raw/olist_order_reviews_dataset.csv' CSV HEADER;

-- Sincronizar datos a tabla particionada después de cargar orders.
INSERT INTO orders_part
SELECT * FROM orders
ON CONFLICT DO NOTHING;
