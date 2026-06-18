# Monitoreo de rendimiento

## PostgreSQL / Supabase

Métricas mínimas:

- `Execution Time`.
- `Planning Time`.
- `Buffers: shared hit/read`.
- Tipo de scan: Seq Scan, Index Scan, Bitmap Index Scan.
- Uso de particiones en `orders_part`.

Comando:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...;
```

## MongoDB Atlas

Métricas mínimas:

- `executionTimeMillis`.
- `totalDocsExamined`.
- `totalKeysExamined`.
- `nReturned`.
- Índice usado.
- Performance Advisor.
- Slow Query Log.
- `$indexStats`.

## Ratio de eficiencia

```text
efficiency_ratio = totalDocsExamined / max(nReturned, 1)
```

## Mejora porcentual

```text
improvement_percent = ((before_ms - after_ms) / before_ms) * 100
```
