-- 01_extensions.sql
-- Extensiones requeridas por la rúbrica de la Etapa 2.
-- Ejecutar en Supabase/PostgreSQL antes de crear tipos, tablas e índices.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
