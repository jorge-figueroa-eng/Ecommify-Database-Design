-- Query critica 5: consulta geografica PostGIS.
-- Punto de referencia aproximado: Sao Paulo.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT geolocation_zip_code_prefix, geolocation_city, geolocation_state,
       ST_Distance(geom, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography) AS distance_meters
FROM geolocations
WHERE ST_DWithin(geom, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography, 5000)
ORDER BY distance_meters
LIMIT 50;
