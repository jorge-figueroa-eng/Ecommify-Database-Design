# Ecommify - Entrega Etapa 2: Implementacion tecnica PostgreSQL y MongoDB

Este paquete contiene una entrega completa para la **Etapa 2 - Implementacion tecnica completa en PostgreSQL y MongoDB**.
Incluye documento tecnico, scripts SQL, scripts MongoDB, pipelines, plantillas de evidencias, notebooks de Colab y guion de video.

> Nota importante: las metricas reales de `EXPLAIN ANALYZE` y `.explain("executionStats")` deben generarse en la instancia final de Supabase y MongoDB Atlas del equipo. El paquete incluye scripts y plantillas para capturarlas sin inventar resultados.

## 1. Estructura

```text
Ecommify_Etapa2_Completa/
├── README.md
├── .env.example
├── requirements.txt
├── docs/
│   ├── Etapa_2_Documento_Tecnico.md
│   ├── Etapa_2_Documento_Tecnico.docx
│   ├── checklist_rubrica.md
│   ├── sync_postgresql_mongodb.md
│   ├── monitoreo_rendimiento.md
│   ├── limitaciones_y_workarounds.md
│   └── video_demo_script.md
├── postgresql/
│   ├── schema_final/
│   ├── supabase/
│   ├── queries/
│   └── load/
├── mongodb/
│   ├── schema/
│   ├── indexes/
│   ├── pipelines/
│   ├── explain/
│   ├── sharding/
│   └── atlas_monitoring/
├── notebooks/
└── evidences/
```

## 2. Dataset utilizado

| Dataset | Filas | Uso |
|---|---:|---|
| customers | 99,441 | Clientes, ciudad y estado |
| geolocation | 1,000,163 | PostGIS y consultas espaciales |
| order_payments | 103,886 | Metodos de pago y valor pagado |
| order_reviews | 104,719 | Calificaciones y comentarios |
| orders | 99,441 | Ordenes, estados y fechas |
| products | 32,951 | Catalogo de productos |
| sellers | 3,095 | Vendedores por ciudad/estado |
| category_translation | 71 | Traduccion de categorias |

El archivo `olist_order_items_dataset.csv` no fue cargado en esta conversacion. Si el repositorio lo tiene en `postgresql/seed_data/order_items.csv`, se puede cargar con el modelo incluido; si no esta disponible, se debe declarar como limitacion para analisis producto-vendedor-orden.

## 3. Preparacion

1. Crear proyecto en Supabase.
2. Crear cluster en MongoDB Atlas.
3. Copiar `.env.example` a `.env`.
4. Poner las rutas reales de los CSV.
5. Ejecutar scripts PostgreSQL y MongoDB.
6. Guardar capturas y metricas en `evidences/`.

## 4. Variables de entorno

```bash
SUPABASE_DB_URL="postgresql://postgres:<password>@<host>:5432/postgres"
MONGODB_URI="mongodb+srv://<user>:<password>@<cluster>.mongodb.net/ecommify"
MONGODB_DATABASE="ecommify"
DATA_DIR="/content/data"
```

## 5. Ejecucion PostgreSQL

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f postgresql/supabase/run_all_supabase.sql
```

Luego cargar CSV desde Colab usando `notebooks/02_load_to_supabase.ipynb` o adaptar `postgresql/load/01_copy_from_csv.sql`.

## 6. Ejecucion MongoDB Atlas

```bash
mongosh "$MONGODB_URI" mongodb/schema/00_drop_collections.js
mongosh "$MONGODB_URI" mongodb/schema/01_products_catalog_schema.js
mongosh "$MONGODB_URI" mongodb/schema/02_order_reviews_schema.js
mongosh "$MONGODB_URI" mongodb/schema/03_orders_analytics_schema.js
mongosh "$MONGODB_URI" mongodb/schema/04_seller_state_buckets_schema.js
mongosh "$MONGODB_URI" mongodb/schema/05_geolocation_points_schema.js
mongosh "$MONGODB_URI" mongodb/indexes/01_compound_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/02_partial_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/03_text_indexes.js
mongosh "$MONGODB_URI" mongodb/indexes/04_geo_indexes.js
```

La carga y transformacion documental se hace con `notebooks/04_load_to_mongodb_atlas.ipynb`.

## 7. Evidencias obligatorias

Guardar aqui:

```text
evidences/postgresql/postgresql_metrics.csv
evidences/mongodb/mongodb_metrics.csv
evidences/postgresql/screenshots/
evidences/mongodb/screenshots/
evidences/postgresql/explain_before/
evidences/postgresql/explain_after/
evidences/mongodb/explain_before/
evidences/mongodb/explain_after/
```

## 8. Entregables finales

- Documento tecnico: `docs/Etapa_2_Documento_Tecnico.md` o `.docx`.
- Repositorio GitHub actualizado con esta estructura.
- Video de 5 a 10 minutos siguiendo `docs/video_demo_script.md`.
