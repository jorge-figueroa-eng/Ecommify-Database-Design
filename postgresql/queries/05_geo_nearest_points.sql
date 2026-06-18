EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    ST_Distance(
        geom,
        ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography
    ) AS distance_meters
FROM geolocations
ORDER BY geom <-> ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography
LIMIT 20;
