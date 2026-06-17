# Estadisticas de uso de indices

Ejecutar en mongosh:

```javascript
db.orders_analytics.aggregate([{ $indexStats: {} }]);
db.order_reviews.aggregate([{ $indexStats: {} }]);
db.products_catalog.aggregate([{ $indexStats: {} }]);
```

Guardar salida en `evidences/mongodb/explain_after/index_stats.json`.
