-- 07_materialized_views.sql
-- Vista materializada para acelerar dashboard analítico.

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_order_summary AS
SELECT
    c.customer_state,
    date_trunc('month', o.order_purchase_timestamp) AS purchase_month,
    o.order_status,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_state, date_trunc('month', o.order_purchase_timestamp), o.order_status;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_order_summary_unique
ON mv_monthly_order_summary (customer_state, purchase_month, order_status);
