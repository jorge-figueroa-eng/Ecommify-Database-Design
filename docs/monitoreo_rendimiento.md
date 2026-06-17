# Monitoreo de rendimiento

## PostgreSQL/Supabase

Ejecutar:

```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT ...;
```

Revisar:

- Execution Time.
- Planning Time.
- Seq Scan vs Index Scan.
- Buffers hit/read.
- Rows removed by filter.

## MongoDB Atlas

Revisar:

- Performance Advisor.
- Slow Query Log.
- Query Targeting.
- Index Stats.

Comando:

```javascript
db.orders_analytics.aggregate([{ $indexStats: {} }]);
```

## Evidencia minima

Capturas en:

- `evidences/postgresql/screenshots/`
- `evidences/mongodb/screenshots/`
