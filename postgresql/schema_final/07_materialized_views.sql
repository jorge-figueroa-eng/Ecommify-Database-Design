-- 07_materialized_views.sql
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_order_summary AS
SELECT
  c.customer_state,
  date_trunc('month', o.order_purchase_timestamp) AS month,
  o.order_status,
  COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_state, date_trunc('month', o.order_purchase_timestamp), o.order_status;

CREATE INDEX IF NOT EXISTS idx_mv_monthly_order_summary
ON mv_monthly_order_summary (customer_state, month, order_status);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_payment_method_summary AS
SELECT
  payment_type,
  COUNT(*) AS total_payments,
  SUM(payment_value) AS total_value,
  AVG(payment_value) AS avg_value
FROM order_payments
GROUP BY payment_type;

CREATE INDEX IF NOT EXISTS idx_mv_payment_method_summary_type
ON mv_payment_method_summary (payment_type);
