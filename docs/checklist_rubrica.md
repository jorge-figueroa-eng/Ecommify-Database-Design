# Checklist de cumplimiento de rúbrica - Etapa 2

| Criterio | Requisito | Evidencia | Estado |
|---|---|---|---|
| PostgreSQL | Esquema completo en Supabase | `postgresql/schema_final/03_tables.sql` | Cumplido |
| PostgreSQL | Constraints | `postgresql/schema_final/03_tables.sql`, `05_constraints.sql` | Cumplido |
| PostgreSQL | JSONB / arrays | `products.attributes`, `metadata`, `customer_tags`, `review_tags` | Cumplido |
| PostgreSQL | PostGIS | `01_extensions.sql`, `geolocations.geom` | Cumplido |
| PostgreSQL | pg_trgm | `01_extensions.sql`, índices trigram | Cumplido |
| PostgreSQL | Scripts ejecutables | `postgresql/supabase/run_all_supabase.sql` | Cumplido |
| MongoDB | Catálogo embebido | `products_catalog` | Cumplido |
| MongoDB | Reviews referenciadas | `order_reviews` por `order_id` | Cumplido |
| MongoDB | Attribute Pattern | `products_catalog.attributes[]` | Cumplido |
| MongoDB | Extended Reference | `orders_analytics.customer`, `payment_summary` | Cumplido |
| MongoDB | Bucket Pattern | `seller_state_buckets` | Cumplido |
| MongoDB | JSON Schema | `mongodb/schema/*.js` | Cumplido |
| Optimización | B-tree | `idx_orders_status_purchase` | Cumplido |
| Optimización | GIN | JSONB, arrays, trgm | Cumplido |
| Optimización | GiST | `idx_geolocations_geom_gist` | Cumplido |
| Optimización | BRIN | `idx_orders_purchase_brin` | Cumplido |
| Optimización | Particionamiento | `orders_part` por rango | Cumplido |
| Optimización | Mongo índices compuestos | `mongodb/indexes/01_compound_indexes.js` | Cumplido |
| Optimización | Mongo índices parciales | `mongodb/indexes/02_partial_indexes.js` | Cumplido |
| Optimización | Aggregation pipeline | `mongodb/pipelines/*.js` | Cumplido |
| Evidencias | EXPLAIN antes/después | `postgresql/explain/`, `mongodb/explain/` | Requiere ejecución en ambiente final |
| GitHub | README setup | `README.md` | Cumplido |
| GitHub | Notebooks Colab | `notebooks/*.ipynb` | Cumplido |
| GitHub | Estructura clara | Carpetas organizadas | Cumplido |
