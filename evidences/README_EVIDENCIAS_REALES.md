# Evidencias reales requeridas para entregar

Este repositorio contiene todos los scripts para cumplir la rúbrica. Para que el docente valide el 100%, se deben agregar evidencias reales generadas en el ambiente final:

## PostgreSQL / Supabase

Guardar capturas:

- `evidences/postgresql/screenshots/01_supabase_tables.png`
- `evidences/postgresql/screenshots/02_supabase_extensions.png`
- `evidences/postgresql/screenshots/03_supabase_indexes.png`
- `evidences/postgresql/screenshots/04_partitioned_orders.png`
- `evidences/postgresql/screenshots/05_explain_after.png`

Llenar:

- `evidences/postgresql/postgresql_metrics.csv`

## MongoDB Atlas

Guardar capturas:

- `evidences/mongodb/screenshots/01_collections.png`
- `evidences/mongodb/screenshots/02_indexes.png`
- `evidences/mongodb/screenshots/03_performance_advisor.png`
- `evidences/mongodb/screenshots/04_explain_executionStats.png`

Llenar:

- `evidences/mongodb/mongodb_metrics.csv`

No se deben inventar métricas. Deben salir de `EXPLAIN ANALYZE` y `.explain("executionStats")`.
