-- run_all_supabase.sql
-- Script maestro para ejecutar desde la raíz del repositorio con psql.
-- Comando recomendado:
-- psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/supabase/run_all_supabase.sql

\echo '==> Creando extensiones requeridas'
\i postgresql/schema_final/01_extensions.sql

\echo '==> Creando tipos, dominios y tipos compuestos'
\i postgresql/schema_final/02_types.sql

\echo '==> Creando tablas principales'
\i postgresql/schema_final/03_tables.sql

\echo '==> Creando particiones declarativas'
\i postgresql/schema_final/04_partitions.sql

\echo '==> Aplicando constraints adicionales'
\i postgresql/schema_final/05_constraints.sql

\echo '==> Creando índices especializados'
\i postgresql/schema_final/06_indexes.sql

\echo '==> Creando vistas materializadas'
\i postgresql/schema_final/07_materialized_views.sql

\echo '==> Validación rápida de extensiones instaladas'
SELECT extname AS extension_name
FROM pg_extension
WHERE extname IN ('postgis', 'pg_trgm', 'btree_gin', 'unaccent', 'pgcrypto')
ORDER BY extname;

\echo '==> Validación rápida de tablas creadas'
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type IN ('BASE TABLE', 'VIEW')
ORDER BY table_name;
