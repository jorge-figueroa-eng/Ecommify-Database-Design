EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    c.customer_state,
    COUNT(*) AS late_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY c.customer_state
ORDER BY late_orders DESC;
