-- Ejecutar después de crear índices especializados con 06_indexes.sql.
\echo 'Q1 orders_by_state_month AFTER'
\i postgresql/queries/01_orders_by_state_month.sql
\echo 'Q2 payments_by_type AFTER'
\i postgresql/queries/02_payments_by_type.sql
\echo 'Q3 late_deliveries AFTER'
\i postgresql/queries/03_late_deliveries.sql
\echo 'Q4 city_trigram_search AFTER'
\i postgresql/queries/04_city_trigram_search.sql
