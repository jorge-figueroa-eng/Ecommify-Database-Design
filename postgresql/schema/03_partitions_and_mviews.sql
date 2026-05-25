-- 03_partitions_and_mviews.sql
-- Vistas materializadas y consultas OLAP para la arquitectura hibrida.

CREATE MATERIALIZED VIEW mv_sales_by_category_monthly AS
SELECT
    date_trunc('month', o.order_purchase_timestamp)::date AS sales_month,
    c.name_en AS category_name_en,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_items,
    SUM(oi.price) AS gross_product_revenue,
    SUM(oi.freight_value) AS total_freight
FROM orders o
JOIN order_items oi
  ON oi.order_id = o.order_id
 AND oi.order_purchase_timestamp = o.order_purchase_timestamp
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN categories c ON c.category_id = p.category_id
GROUP BY 1, 2;

CREATE UNIQUE INDEX idx_mv_sales_by_category_monthly
ON mv_sales_by_category_monthly(sales_month, category_name_en);

CREATE MATERIALIZED VIEW mv_customer_segments AS
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(op.payment_value) AS total_spent,
    AVG(op.payment_value) AS avg_ticket,
    MAX(o.order_purchase_timestamp) AS last_purchase_at,
    CASE
        WHEN SUM(op.payment_value) >= 1000 THEN 'high_value'
        WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 'repeat_customer'
        ELSE 'standard'
    END AS customer_segment
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_payments op
  ON op.order_id = o.order_id
 AND op.order_purchase_timestamp = o.order_purchase_timestamp
GROUP BY c.customer_unique_id;

CREATE UNIQUE INDEX idx_mv_customer_segments ON mv_customer_segments(customer_unique_id);

-- Mantenimiento sugerido:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_category_monthly;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_segments;
-- VACUUM (ANALYZE) orders;
