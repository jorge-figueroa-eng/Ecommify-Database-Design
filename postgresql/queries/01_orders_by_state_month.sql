EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    c.customer_state,
    date_trunc('month', o.order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-01-01'
GROUP BY c.customer_state, date_trunc('month', o.order_purchase_timestamp)
ORDER BY purchase_month, total_orders DESC;
