-- 01_extensions.sql
-- Extensiones requeridas por la rubrica: PostGIS para geolocalizacion y pg_trgm para busquedas tolerantes.
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
