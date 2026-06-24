# Paso a paso para tomar evidencias de la Etapa 2

## 1. Preparar el repositorio local

```bash
git clone https://github.com/jorge-figueroa-eng/Ecommify-Database-Design.git
cd Ecommify-Database-Design
cp .env.example .env
```

Editar `.env` con:

```bash
SUPABASE_DB_URL="postgresql://postgres:<password>@<host>:5432/postgres"
MONGODB_URI="mongodb+srv://<user>:<password>@<cluster>.mongodb.net/ecommify"
MONGODB_DATABASE="ecommify"
DATA_DIR="/ruta/a/csv"
```

## 2. Reemplazar los archivos corregidos

Copiar los archivos de este ZIP sobre el repositorio respetando las rutas.

```bash
cp -R ecommify_archivos_corregidos/* Ecommify-Database-Design/
```

## 3. Ejecutar PostgreSQL en Supabase

Desde la raíz del repositorio:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/supabase/run_all_supabase.sql
```

### Evidencia que debes capturar

Guardar capturas en:

```text
evidences/postgresql/screenshots/
```

Capturas mínimas:

```text
01_extensions_enabled.png
02_tables_created.png
03_indexes_created.png
04_partitions_created.png
05_materialized_view_created.png
```

### Consultas de validación para capturas

Extensiones:

```sql
SELECT extname
FROM pg_extension
WHERE extname IN ('postgis', 'pg_trgm', 'btree_gin', 'unaccent', 'pgcrypto')
ORDER BY extname;
```

Tablas:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Índices:

```sql
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

Particiones:

```sql
SELECT
    parent.relname AS parent_table,
    child.relname AS partition_table
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
WHERE parent.relname = 'orders_part'
ORDER BY child.relname;
```

## 4. Cargar datos en PostgreSQL

Usar el notebook:

```text
notebooks/02_load_to_supabase.ipynb
```

O adaptar el script:

```text
postgresql/load/copy_commands.sql
```

Después de cargar `orders`, llenar la tabla particionada:

```sql
INSERT INTO orders_part (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    raw_payload
)
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    raw_payload
FROM orders
ON CONFLICT DO NOTHING;
```

## 5. Tomar evidencia PostgreSQL antes/después

La forma correcta es tomar el `antes` antes de crear los índices, y el `después` luego de ejecutar `06_indexes.sql`.

Si ya creaste índices, puedes hacer una prueba controlada en una base limpia:

1. Ejecutar `00_drop_all.sql` si es ambiente de prueba.
2. Ejecutar extensiones, tipos, tablas, particiones y constraints.
3. Cargar datos.
4. Ejecutar las consultas con `EXPLAIN (ANALYZE, BUFFERS)` y guardar evidencia `before`.
5. Ejecutar `06_indexes.sql`.
6. Ejecutar otra vez las mismas consultas y guardar evidencia `after`.

Crear carpetas:

```bash
mkdir -p evidences/postgresql/explain_before
mkdir -p evidences/postgresql/explain_after
```

Ejemplo de captura en consola:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 \
  -c "EXPLAIN (ANALYZE, BUFFERS) SELECT c.customer_state, date_trunc('month', o.order_purchase_timestamp) AS month, COUNT(*) AS total_orders FROM orders o JOIN customers c ON c.customer_id = o.customer_id WHERE o.order_status = 'delivered' AND o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-01-01' GROUP BY c.customer_state, date_trunc('month', o.order_purchase_timestamp) ORDER BY month, total_orders DESC;" \
  > evidences/postgresql/explain_after/q01_orders_by_state_month_after.txt
```

Repetir para cada consulta crítica y llenar:

```text
evidences/postgresql/postgresql_metrics.csv
```

Fórmula para `improvement_percent`:

```text
((execution_time_before_ms - execution_time_after_ms) / execution_time_before_ms) * 100
```

## 6. Ejecutar MongoDB Atlas

Crear colecciones:

```bash
mongosh "$MONGODB_URI" mongodb/schema/00_drop_collections.js
mongosh "$MONGODB_URI" mongodb/schema/01_products_catalog_schema.js
mongosh "$MONGODB_URI" mongodb/schema/02_order_reviews_schema.js
mongosh "$MONGODB_URI" mongodb/schema/03_orders_analytics_schema.js
mongosh "$MONGODB_URI" mongodb/schema/04_seller_state_buckets_schema.js
mongosh "$MONGODB_URI" mongodb/schema/05_geolocation_points_schema.js
```

Cargar datos usando:

```text
notebooks/04_load_to_mongodb_atlas.ipynb
```

## 7. Tomar evidencia MongoDB antes/después

Antes de crear índices:

```bash
mkdir -p evidences/mongodb/explain_before
mkdir -p evidences/mongodb/explain_after

mongosh "$MONGODB_URI" mongodb/explain/before/01_explain_revenue_before.js \
  > evidences/mongodb/explain_before/01_revenue_by_state_payment_before.json
```

Crear índices:

```bash
mongosh "$MONGODB_URI" mongodb/indexes/01_compound_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/02_partial_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/03_text_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/04_geo_indexes.js
```

Después de crear índices:

```bash
mongosh "$MONGODB_URI" mongodb/explain/after/01_explain_revenue_after.js \
  > evidences/mongodb/explain_after/01_revenue_by_state_payment_after.json
```

Llenar:

```text
evidences/mongodb/mongodb_metrics.csv
```

Campos que debes extraer del JSON:

```text
executionTimeMillis
totalDocsExamined
totalKeysExamined
nReturned
```

Fórmulas:

```text
efficiency = totalDocsExamined / nReturned
improvement_percent = ((execution_time_before_ms - execution_time_after_ms) / execution_time_before_ms) * 100
```

## 8. Capturas de MongoDB Atlas

Guardar en:

```text
evidences/mongodb/screenshots/
```

Capturas mínimas:

```text
01_collections_created.png
02_json_schema_validation.png
03_indexes_created.png
04_pipeline_execution.png
05_performance_advisor.png
06_index_stats.png
```

En Atlas debes mostrar:

- Colecciones `products_catalog`, `order_reviews`, `orders_analytics`, `seller_state_buckets`, `geolocation_points`.
- Índices compuestos, parciales, texto y geoespaciales.
- Resultado de pipeline.
- Performance Advisor o métricas del clúster.

## 9. Actualizar documento técnico

Después de llenar los CSV y guardar capturas, actualizar:

```text
actividad5/DOCUMENTO_TECNICO.md
```

En la sección de evidencias, pegar los valores reales de:

- Tiempo antes.
- Tiempo después.
- Porcentaje de mejora.
- Scan usado antes/después.
- Documentos examinados antes/después en MongoDB.

## 10. Subir a GitHub

```bash
git add .
git commit -m "Completa evidencias cuantitativas Etapa 2"
git push
```

## 11. Evidencia del video

Grabar video de 5 a 10 minutos y subir el enlace en:

```text
docs/video_link.md
```

El video debe mostrar:

1. Conexión a Supabase.
2. Tablas, extensiones, particiones e índices PostgreSQL.
3. EXPLAIN ANALYZE antes/después.
4. Conexión a MongoDB Atlas.
5. Colecciones, JSON Schema e índices MongoDB.
6. Pipeline y .explain("executionStats").
7. Decisiones técnicas: PostgreSQL para consistencia, MongoDB para analítica documental, y uso de índices/particionamiento/sharding teórico.
