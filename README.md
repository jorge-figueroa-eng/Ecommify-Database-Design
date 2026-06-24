# Ecommify Database Optimization - Etapa 2

Repositorio preparado para cumplir la rúbrica de la **Etapa 2: Implementación técnica completa en PostgreSQL y MongoDB**.

Incluye:

- Implementación PostgreSQL/Supabase con esquema completo, constraints, tipos avanzados, extensiones, particionamiento e índices especializados.
- Implementación MongoDB Atlas con modelado documental, JSON Schema, Attribute Pattern, Extended Reference Pattern y Bucket Pattern.
- Optimización con índices B-tree, GIN, GiST, BRIN en PostgreSQL e índices compuestos, parciales, texto y geoespaciales en MongoDB.
- Pipelines de aggregation con mínimo 5 stages, `allowDiskUse`, `.explain("executionStats")` y plantillas para evidencias cuantitativas antes/después.
- Documentación técnica, sincronización PostgreSQL → MongoDB, sharding teórico, replica set, monitoreo y guion de video.

> Nota de entrega: las métricas reales de ejecución deben obtenerse en la instancia final de Supabase y MongoDB Atlas del equipo. Este repositorio trae los scripts exactos para generarlas y los CSV listos para llenar con resultados reales.

## 1. Tecnologías

- PostgreSQL / Supabase
- MongoDB Atlas
- PostGIS
- pg_trgm
- Python 3.11+
- Google Colab / Jupyter
- mongosh
- psql

## 2. Dataset esperado

Ubicar los CSV en `data/raw/`:

```text
olist_customers_dataset.csv
olist_geolocation_dataset.csv
olist_order_payments_dataset.csv
olist_order_reviews_dataset.csv
olist_orders_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
olist_order_items_dataset.csv                 # recomendado para análisis producto-vendedor
product_category_name_translation.csv
```

Si no se tiene `olist_order_items_dataset.csv`, documentar la limitación en `docs/limitaciones_y_workarounds.md`.

## 3. Variables de entorno

Copiar `.env.example` a `.env` y completar:

```bash
SUPABASE_DB_URL="postgresql://USER:PASSWORD@HOST:PORT/postgres"
MONGODB_URI="mongodb+srv://USER:PASSWORD@CLUSTER.mongodb.net/ecommify"
MONGODB_DATABASE="ecommify"
```

## 4. Ejecución PostgreSQL en Supabase

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/supabase/run_all_supabase.sql
```

Carga de datos:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/load/copy_commands.sql
```

Evidencias PostgreSQL:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/explain/before/01_run_explain_before.sql > evidences/postgresql/explain_before/explain_before.txt
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/explain/after/01_run_explain_after.sql > evidences/postgresql/explain_after/explain_after.txt
```

## 5. Ejecución MongoDB Atlas

```bash
mongosh "$MONGODB_URI" mongodb/schema/01_products_catalog_schema.js
mongosh "$MONGODB_URI" mongodb/schema/02_order_reviews_schema.js
mongosh "$MONGODB_URI" mongodb/schema/03_orders_analytics_schema.js
mongosh "$MONGODB_URI" mongodb/schema/04_seller_state_buckets_schema.js
mongosh "$MONGODB_URI" mongodb/schema/05_geolocation_points_schema.js
```

Crear índices:

```bash
mongosh "$MONGODB_URI" mongodb/indexes/01_compound_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/02_partial_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/03_text_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/04_geo_indexes.js
```

Ejecutar pipelines:

```bash
mongosh "$MONGODB_URI" mongodb/pipelines/01_revenue_by_state_payment.js
mongosh "$MONGODB_URI" mongodb/pipelines/02_reviews_quality_pipeline.js
mongosh "$MONGODB_URI" mongodb/pipelines/03_product_catalog_search_pipeline.js
```

Evidencias MongoDB:

```bash
mongosh "$MONGODB_URI" mongodb/explain/before/01_explain_revenue_before.js > evidences/mongodb/explain_before/revenue_before.json
mongosh "$MONGODB_URI" mongodb/explain/after/01_explain_revenue_after.js > evidences/mongodb/explain_after/revenue_after.json
```

## 6. Estructura principal

```text
postgresql/schema_final/       DDL completo ejecutable en Supabase
postgresql/queries/            Queries críticas optimizadas
postgresql/explain/            Scripts EXPLAIN antes/después
mongodb/schema/                Colecciones con JSON Schema
mongodb/indexes/               Índices compuestos, parciales, texto, geo
mongodb/pipelines/             Aggregation pipelines optimizados
mongodb/sharding/              Diseño teórico sharding y replica set
evidences/                     Métricas, capturas y resultados antes/después
notebooks/                     Notebooks Colab documentados
docs/                          Documento técnico, checklist y 
```

## 7. Archivos clave para entrega

- `docs/Documento_Tecnico.md`
- `docs/checklist_rubrica.md`
- `evidences/postgresql/postgresql_metrics.csv`
- `evidences/mongodb/mongodb_metrics.csv`
