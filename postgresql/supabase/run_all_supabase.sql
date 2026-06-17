-- run_all_supabase.sql
-- Ejecutar desde la raiz del paquete:
-- psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/supabase/run_all_supabase.sql

\i postgresql/schema_final/01_extensions.sql
\i postgresql/schema_final/02_types.sql
\i postgresql/schema_final/03_tables.sql
\i postgresql/schema_final/04_partitions.sql
\i postgresql/schema_final/05_constraints.sql
\i postgresql/schema_final/06_indexes.sql
\i postgresql/schema_final/07_materialized_views.sql
