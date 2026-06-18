# Documento técnico de implementación - Etapa 2

## 1. Resumen ejecutivo

La implementación técnica de Ecommify integra PostgreSQL/Supabase y MongoDB Atlas para resolver necesidades transaccionales y analíticas. PostgreSQL se utiliza para integridad referencial, constraints, particionamiento, tipos avanzados y consultas SQL optimizadas. MongoDB Atlas se utiliza para modelos documentales orientados a lectura, catálogo enriquecido, reviews referenciadas y analítica agregada.

Las optimizaciones principales son:

- Extensiones PostgreSQL: PostGIS para geolocalización, pg_trgm para búsqueda aproximada, btree_gin para índices especializados, unaccent y pgcrypto.
- Tipos avanzados PostgreSQL: JSONB, arrays, dominios, enums, tipos compuestos y geography.
- Particionamiento declarativo por rango temporal en `orders_part`.
- Índices B-tree, GIN, GiST, BRIN y parciales.
- JSON Schema en MongoDB Atlas.
- Attribute Pattern, Extended Reference Pattern y Bucket Pattern.
- Índices MongoDB compuestos ESR, parciales, texto y geoespaciales.
- Aggregation pipelines con más de cinco stages y `allowDiskUse`.

## 2. Arquitectura general

```text
CSV Olist
   |
   |-- PostgreSQL / Supabase
   |     - Modelo relacional normalizado
   |     - Constraints y tipos avanzados
   |     - PostGIS y pg_trgm
   |     - Particionamiento e índices
   |
   |-- MongoDB Atlas
         - Catálogo documental
         - Reviews referenciadas
         - Órdenes analíticas
         - Buckets regionales
```

## 3. Implementación PostgreSQL

### 3.1 Esquema

El esquema incluye:

- `customers`
- `geolocations`
- `sellers`
- `product_categories`
- `products`
- `orders`
- `orders_part`
- `order_items`
- `order_payments`
- `order_reviews`
- `outbox_events`

### 3.2 Tipos avanzados

Se implementan:

- `JSONB`: metadata, atributos, payloads y eventos.
- `TEXT[]`: etiquetas y tokens de búsqueda.
- `GEOGRAPHY(Point, 4326)`: geolocalización.
- `ENUM`: estados de orden y tipos de pago.
- `DOMAIN`: estados de Brasil.
- `TYPE address_br`: dirección compuesta.

### 3.3 Extensiones

- `postgis`: consultas geoespaciales.
- `pg_trgm`: búsqueda aproximada en texto.
- `btree_gin`: soporte a índices avanzados.
- `unaccent`: normalización de texto.
- `pgcrypto`: generación de UUID en outbox.

### 3.4 Particionamiento

La tabla `orders_part` está particionada por rango de `order_purchase_timestamp`, permitiendo pruning por año y reduciendo el volumen de datos escaneado en consultas temporales.

### 3.5 Índices

Se implementan:

- B-tree: `idx_orders_status_purchase`.
- BRIN: `idx_orders_purchase_brin`.
- GiST: `idx_geolocations_geom_gist`.
- GIN JSONB: `idx_products_attributes_gin`.
- GIN trigram: `idx_geolocations_city_trgm`, `idx_reviews_comment_trgm`.
- Parciales: órdenes entregadas y reviews negativas con comentario.

### 3.6 Evidencias

Las evidencias deben guardarse en:

- `evidences/postgresql/explain_before/`
- `evidences/postgresql/explain_after/`
- `evidences/postgresql/postgresql_metrics.csv`

## 4. Implementación MongoDB Atlas

### 4.1 Colecciones

- `products_catalog`
- `order_reviews`
- `orders_analytics`
- `seller_state_buckets`
- `geolocation_points`

### 4.2 Catálogo embebido

`products_catalog` embebe categoría, métricas, dimensiones y atributos del producto. Esto reduce joins y permite búsquedas rápidas por categoría y atributos.

### 4.3 Reviews referenciadas

`order_reviews` se referencia por `order_id`. Esta decisión evita documentos de producto u orden con crecimiento indefinido.

### 4.4 Patrones de diseño

| Patrón | Colección | Aplicación |
|---|---|---|
| Attribute Pattern | `products_catalog` | Atributos variables como pares `k/v`. |
| Extended Reference | `orders_analytics` | Cliente y pago resumidos dentro de la orden. |
| Bucket Pattern | `seller_state_buckets` | Vendedores agrupados por estado. |

### 4.5 JSON Schema

Cada colección se crea con `db.createCollection()` y validador `$jsonSchema`, garantizando estructura mínima y tipos esperados.

### 4.6 Índices MongoDB

- Compuestos ESR: `idx_orders_state_status_purchase_esr`.
- Parciales: `idx_low_score_reviews_with_comment`.
- Texto: `idx_reviews_text_search`, `idx_products_text_search`.
- Geo: `idx_geolocation_points_2dsphere`.

### 4.7 Aggregation pipelines

El pipeline principal usa:

- `$match`
- `$lookup`
- `$unwind`
- `$addFields`
- `$group`
- `$project`
- `$sort`
- `$facet`
- `allowDiskUse: true`

## 5. Evidencias cuantitativas

### PostgreSQL

Las consultas se evalúan con:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

Métricas:

- Execution Time.
- Planning Time.
- Buffers hit/read.
- Tipo de scan.
- Uso de índices.

### MongoDB

Las consultas se evalúan con:

```javascript
db.collection.explain("executionStats").aggregate([...])
```

Métricas:

- `executionTimeMillis`.
- `totalDocsExamined`.
- `totalKeysExamined`.
- `nReturned`.
- Ratio de eficiencia.

## 6. Sincronización entre sistemas

La sincronización propuesta usa Transactional Outbox. PostgreSQL mantiene la fuente transaccional y MongoDB se actualiza de forma eventual para consultas analíticas.

## 7. Sharding y replica sets

La shard key propuesta para `orders_analytics` es:

```javascript
{ "customer.state": 1, "purchase_year_month": 1, "order_id": "hashed" }
```

La topología de replica set propone tres nodos con Read/Write Concern diferenciado por criticidad de operación.

## 8. Lecciones aprendidas

- Los índices deben diseñarse con base en las consultas críticas, no de forma genérica.
- MongoDB mejora lecturas analíticas cuando el modelo se diseña según patrones de acceso.
- PostgreSQL conserva ventajas fuertes para integridad, constraints y transacciones.
- Las evidencias antes/después son indispensables para justificar la mejora.

## 9. Conclusiones

La solución cumple los objetivos de optimización al combinar fortalezas de PostgreSQL y MongoDB. PostgreSQL garantiza integridad y consultas relacionales eficientes; MongoDB Atlas facilita modelos documentales optimizados para lectura, búsqueda y análisis agregado. La implementación queda preparada para ser reproducible mediante scripts, notebooks y documentación técnica.
