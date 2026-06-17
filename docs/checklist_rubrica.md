# Checklist de cumplimiento de rubrica - Etapa 2

| Criterio | Requisito | Archivo/Evidencia | Estado |
|---|---|---|---|
| PostgreSQL | Esquema completo en Supabase | `postgresql/schema_final/03_tables.sql` | listo |
| PostgreSQL | Constraints | `03_tables.sql`, `05_constraints.sql` | listo |
| PostgreSQL | JSONB | multiples tablas | listo |
| PostgreSQL | Arrays | customers, sellers, reviews, products | listo |
| PostgreSQL | PostGIS | `01_extensions.sql`, `geolocations.geom` | listo |
| PostgreSQL | pg_trgm | `01_extensions.sql`, indices trigram | listo |
| PostgreSQL | Scripts ejecutables | `supabase/run_all_supabase.sql` | listo |
| MongoDB | Colecciones | `mongodb/schema/*.js` | listo |
| MongoDB | JSON Schema | `mongodb/schema/*.js` | listo |
| MongoDB | Attribute Pattern | `products_catalog` | listo |
| MongoDB | Extended Reference | `orders_analytics` | listo |
| MongoDB | Bucket Pattern | `seller_state_buckets` | listo |
| Optimizacion | B-tree | `06_indexes.sql` | listo |
| Optimizacion | GIN | `06_indexes.sql` | listo |
| Optimizacion | GiST | `06_indexes.sql` | listo |
| Optimizacion | BRIN | `06_indexes.sql` | listo |
| Optimizacion | Particionamiento | `04_partitions.sql` | listo |
| Optimizacion | Mongo indices compuestos | `mongodb/indexes/01_compound_indexes.js` | listo |
| Optimizacion | Mongo indices parciales | `mongodb/indexes/02_partial_indexes.js` | listo |
| Optimizacion | Aggregation pipeline 5+ stages | `mongodb/pipelines/01_revenue_by_state_payment.js` | listo |
| Evidencias | EXPLAIN antes/despues PostgreSQL | `evidences/postgresql/` | completar al ejecutar |
| Evidencias | explain executionStats antes/despues MongoDB | `evidences/mongodb/` | completar al ejecutar |
| GitHub | README completo | `README.md` | listo |
| GitHub | Notebooks Colab | `notebooks/*.ipynb` | listo |
| GitHub | Carpeta evidencias | `evidences/` | listo |
| Video | Guion 5 a 10 minutos | `docs/video_demo_script.md` | listo |
