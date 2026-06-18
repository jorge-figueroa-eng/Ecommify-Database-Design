EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT geolocation_city, geolocation_state, COUNT(*) AS points
FROM geolocations
WHERE unaccent(geolocation_city) ILIKE unaccent('%sao paulo%')
GROUP BY geolocation_city, geolocation_state
ORDER BY points DESC;
