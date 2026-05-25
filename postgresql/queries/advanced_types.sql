-- 1. Consulta JSONB: productos con peso mayor a 1000 g según especificaciones.
SELECT product_id, product_specifications
FROM products
WHERE product_specifications @> '{"logistics":{"weight_class":"heavy"}}';

-- 2. Consulta ARRAY: productos con token de busqueda "technology".
SELECT product_id, search_tokens
FROM products
WHERE search_tokens @> ARRAY['technology'];

-- 3. Ranges: promociones activas en la fecha actual.
SELECT promotion_id, product_id, discount_percentage
FROM product_promotions
WHERE promotion_period @> now();

-- 4. pg_trgm: busqueda tolerante a errores tipograficos.
SELECT category_id, name_en, similarity(name_en, 'computer accesories') AS score
FROM categories
WHERE name_en % 'computer accesories'
ORDER BY score DESC;

-- 5. PostGIS: distancia entre dos codigos postales.
SELECT
    a.zip_code_prefix AS seller_zip,
    b.zip_code_prefix AS customer_zip,
    ST_Distance(a.geo_point, b.geo_point) / 1000 AS distance_km
FROM geo_locations a
CROSS JOIN geo_locations b
WHERE a.zip_code_prefix = 1001
  AND b.zip_code_prefix = 13050;
