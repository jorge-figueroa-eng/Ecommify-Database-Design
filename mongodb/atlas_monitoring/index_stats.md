# Estadísticas de uso de índices

Comando:

```javascript
db.orders_analytics.aggregate([{ $indexStats: {} }])
db.order_reviews.aggregate([{ $indexStats: {} }])
db.products_catalog.aggregate([{ $indexStats: {} }])
```

Guardar resultados en:

`evidences/mongodb/explain_after/index_stats.json`
