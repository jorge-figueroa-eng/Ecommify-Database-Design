-- Ejecutar antes de crear índices especializados o tras deshabilitarlos en ambiente de prueba.
\echo 'Q1 orders_by_state_month BEFORE'
\i postgresql/queries/01_orders_by_state_month.sql
\echo 'Q2 payments_by_type BEFORE'
\i postgresql/queries/02_payments_by_type.sql
\echo 'Q3 late_deliveries BEFORE'
\i postgresql/queries/03_late_deliveries.sql
\echo 'Q4 city_trigram_search BEFORE'
\i postgresql/queries/04_city_trigram_search.sql
