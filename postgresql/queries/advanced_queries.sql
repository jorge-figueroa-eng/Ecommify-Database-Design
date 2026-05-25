-- Consultas avanzadas Ecommify PostgreSQL

-- 1. Buscar productos por categoría con tolerancia a errores usando pg_trgm.
SELECT product_category_name, product_category_name_english,
       similarity(product_category_name_english, 'computer accesories') AS score
FROM product_categories
WHERE product_category_name_english % 'computer accesories'
ORDER BY score DESC;

-- 2. Consultar productos que tengan un atributo JSONB específico.
SELECT product_id, specifications
FROM products
WHERE specifications @> '{"has_dimensions": true}'::jsonb;

-- 3. Consultar productos con término de búsqueda en array.
SELECT product_id, product_category_name, search_terms
FROM products
WHERE search_terms @> ARRAY['electronics'];

-- 4. Calcular distancia vendedor-cliente si ambos tienen ubicación geográfica.
SELECT s.seller_id, c.customer_id,
       ST_Distance(s.location, g.location) / 1000 AS distance_km
FROM sellers s
JOIN customers c ON c.customer_zip_code_prefix IS NOT NULL
JOIN geo_zip_summary g ON g.zip_code_prefix = c.customer_zip_code_prefix
WHERE s.location IS NOT NULL AND g.location IS NOT NULL
LIMIT 50;

-- 5. Consultar ventas mensuales por categoría desde vista materializada.
SELECT *
FROM mv_sales_by_category_monthly
ORDER BY month DESC, total_sales DESC
LIMIT 50;

-- 6. Refresh de vistas materializadas.
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_by_category_monthly;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_segments;
