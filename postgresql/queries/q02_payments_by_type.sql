-- Query critica 2: valor por metodo de pago.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT payment_type, COUNT(*) AS total_payments, SUM(payment_value) AS total_value, AVG(payment_value) AS avg_value
FROM order_payments
WHERE payment_value > 0
GROUP BY payment_type
ORDER BY total_value DESC;
