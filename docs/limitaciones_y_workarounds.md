# Limitaciones y workarounds

## Limitaciones del free tier

- MongoDB Atlas free/shared puede limitar sharding real.
- Supabase free tier puede limitar recursos de CPU, memoria y conexiones.
- Las métricas pueden variar según carga del servicio y región.

## Workarounds

- Documentar sharding como diseño teórico, tal como permite la guía.
- Usar `allowDiskUse` en pipelines de MongoDB.
- Crear índices antes de consultas analíticas recurrentes.
- Usar particionamiento declarativo para consultas temporales en PostgreSQL.
- Ejecutar benchmarks varias veces y reportar promedio.

## Dataset incompleto

Si no se dispone de `olist_order_items_dataset.csv`, no se deben inventar ventas por producto-vendedor. Se recomienda documentar la limitación y centrar el análisis en órdenes, pagos, clientes, reviews, catálogo y geolocalización.
