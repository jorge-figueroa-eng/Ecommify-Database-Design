# Guion del video de demostración - 5 a 10 minutos

Duración recomendada: 7 minutos.

## 0:00 - 0:40 Presentación

Presentar objetivo: optimizar el rendimiento del módulo analítico de Ecommify usando PostgreSQL/Supabase y MongoDB Atlas.

## 0:40 - 1:40 Supabase / PostgreSQL

Mostrar:

- Tablas principales.
- Extensiones `postgis` y `pg_trgm`.
- Tipos avanzados: JSONB, arrays, dominios y enums.
- Tabla particionada `orders_part`.

## 1:40 - 2:40 Optimización PostgreSQL

Ejecutar una query crítica con `EXPLAIN ANALYZE`.
Mostrar antes/después:

- Menor tiempo de ejecución.
- Cambio de Seq Scan a Index Scan o Bitmap Index Scan.
- Reducción de buffers leídos.

## 2:40 - 3:40 MongoDB Atlas

Mostrar colecciones:

- `products_catalog`.
- `order_reviews`.
- `orders_analytics`.
- `seller_state_buckets`.

Explicar patrones:

- Attribute Pattern.
- Extended Reference Pattern.
- Bucket Pattern.

## 3:40 - 4:50 Índices y pipeline MongoDB

Mostrar:

- Índice compuesto ESR.
- Índice parcial.
- Índice de texto.
- Pipeline con `$match`, `$lookup`, `$unwind`, `$addFields`, `$group`, `$project`, `$sort`, `$facet`.

## 4:50 - 5:50 Evidencias cuantitativas MongoDB

Mostrar `.explain("executionStats")` antes/después:

- `executionTimeMillis`.
- `totalDocsExamined`.
- `totalKeysExamined`.
- `nReturned`.
- Ratio de eficiencia.

## 5:50 - 6:30 Sharding, replica set y concerns

Explicar:

- Shard key propuesta.
- Riesgo de skew.
- Replica set de tres nodos.
- Read/Write Concern por operación.

## 6:30 - 7:00 Cierre

Cerrar con resultados, impacto y lecciones aprendidas.
