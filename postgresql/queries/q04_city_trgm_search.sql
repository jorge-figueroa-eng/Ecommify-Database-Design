-- Query critica 4: busqueda tolerante de ciudad con pg_trgm.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT geolocation_zip_code_prefix, geolocation_city, geolocation_state
FROM geolocations
WHERE unaccent(geolocation_city) ILIKE unaccent('%sao paulo%')
ORDER BY geolocation_city
LIMIT 50;
