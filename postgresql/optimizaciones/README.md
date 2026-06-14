# Actividad 4 — Optimización PostgreSQL para Ecommify

Optimización de consultas, índices especializados y particionamiento declarativo
sobre la arquitectura híbrida del proyecto, con métricas reales `EXPLAIN (ANALYZE,
BUFFERS)` medidas en PostgreSQL 16 + PostGIS.

## Por qué datos sintéticos

Las semillas reales (`postgresql/seed_data/`) tienen ~200 filas: insuficiente para
que el planificador elija índices o para justificar particionamiento (criterio
>100.000 filas). `generate_data.py` infla los hechos a **1.000.000 de órdenes**
(~1,49 M ítems, ~1,12 M pagos, ~610 K reseñas) muestreando de los CSV reales para
conservar distribuciones realistas.

## Reproducir de cero

```bash
cd actividad4

# 1. Levantar PostgreSQL 16 + PostGIS (parámetros por defecto a propósito)
docker compose up -d

# 2. Generar los CSV sintéticos (~780 MB en data/, reproducible con --seed)
python3 generate_data.py --orders 1000000

# 3. Esquema base (tabla orders PLANA, sin índices de optimización)
export PGPASSWORD=ecommify
DB="postgresql://ecommify:ecommify@localhost:5433/ecommify"
psql "$DB" -v ON_ERROR_STOP=1 -f sql/00_schema_baseline.sql

# 4. Carga masiva + VACUUM ANALYZE + reporte de volúmenes
psql "$DB" -v ON_ERROR_STOP=1 -f sql/00_load.sql
```

> Se usa la imagen multi‑arquitectura `imresamu/postgis:16-3.4` (mismo Dockerfile que
> `postgis/postgis`, mantenido por la comunidad), que corre **nativa en arm64 y amd64**
> sin emulación. La carga completa toma ~30 s.

## Estructura

```
actividad4/
├── docker-compose.yml          # PostgreSQL 16 + PostGIS, puerto host 5433
├── generate_data.py            # generador de datos sintéticos a escala
├── sql/
│   ├── 00_schema_baseline.sql  # esquema "antes" (plano, sin índices extra)
│   ├── 00_load.sql             # carga \copy + post-proceso + volúmenes
│   ├── 01_critical_queries.sql # Fase 1 — consultas OLTP críticas
│   ├── 02_query_optimizations.sql
│   ├── 03_specialized_indexes.sql
│   └── 04_partitioning.sql
├── results/                    # salidas EXPLAIN capturadas
└── REPORTE.md                  # informe consolidado (entregable)
```

## Estado del dataset cargado

| Tabla | Filas | Notas para las fases |
|---|---:|---|
| orders | 1.000.000 | 2016‑09 … 2018‑10 + 1.000 filas en 2019 (→ partición DEFAULT, Fase 3) |
| order_items | 1.489.352 | FK a products (32 K) y sellers (3 K) |
| order_payments | 1.120.365 | mezcla realista de medios de pago |
| order_reviews | 610.215 | puntajes sesgados a 4‑5 |
| customers | 1.000.000 | 496 K personas; 297 K con >1 orden (consulta Q2) |
| outbox_events | 50.000 | 1.035 sin procesar (~2 %) → índice parcial (Q8) |
| product_promotions | 6.000 | 2.000 activas en `now()` (Q6) |

Predicados selectivos disponibles para medir índices: `order_status='created'`
(5.137 filas), outbox sin procesar (1.035), promociones activas (2.000).
