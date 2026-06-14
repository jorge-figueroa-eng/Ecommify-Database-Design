# Actividad 4 — Optimización PostgreSQL para Ecommify

Optimización de consultas, índices especializados y particionamiento declarativo sobre la arquitectura híbrida del proyecto, con métricas reales `EXPLAIN (ANALYZE, BUFFERS)` medidas en PostgreSQL 16 + PostGIS.

---

## 🛠️ Resumen de Optimizaciones Logradas

| Tipo de Optimización | Consulta Bajo Análisis | Latencia Inicial (Baseline) | Latencia Optimizada | Factor de Mejora |
|---|---|---|---|---|
| **Optimización de Consulta** | Q3 (Búsqueda de Vendedores con Geolocalización) | `611.23 ms` | `37.26 ms` | **16.4x** |
| **Índice Compuesto** | Q4 (Órdenes Entregadas con Retraso) | `84.81 ms` | `2.13 ms` | **39.8x** |
| **Índice Parcial** | Q8 (Procesamiento de Outbox Cola Activa) | `10.22 ms` | `0.04 ms` | **255.5x** |
| **Índice GIN (JSONB)** | Q6 (Búsqueda de Especificaciones de Productos) | `372.10 ms` | `0.11 ms` | **3382.7x** |
| **Particionamiento Rango** | Q9 (Volumen mensual histórico por canal de pago) | `265.81 ms` | `10.21 ms` (Partition Pruning) | **26.0x** |

> [!TIP]
> Para ver el análisis profundo de cada plan de ejecución con las métricas detalladas de lectura en disco y búferes, consulta el informe en [REPORTE.md](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/REPORTE.md) o descarga el reporte formal [Actividad 4 - Informe Optimizacion.pdf](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/Actividad%204%20-%20Informe%20Optimizacion.pdf).

---

## 📊 Por qué datos sintéticos

Las semillas reales (`postgresql/seed_data/`) tienen ~200 filas: insuficiente para que el planificador elija índices o para justificar particionamiento (criterio >100.000 filas). `generate_data.py` infla los hechos a **1.000.000 de órdenes** (~1,49 M ítems, ~1,12 M pagos, ~610 K reseñas) muestreando de los CSV reales para conservar distribuciones estadísticas realistas.

---

## ⚙️ Reproducir de cero (Escala 1M órdenes)

1. **Navegar a la carpeta del módulo de optimización**:
   ```bash
   cd postgresql/optimizaciones
   ```

2. **Levantar PostgreSQL 16 + PostGIS (parámetros por defecto a propósito)**:
   ```bash
   docker compose up -d
   ```

3. **Generar los CSV sintéticos (~780 MB en data/, reproducible con --seed)**:
   ```bash
   python3 generate_data.py --orders 1000000
   ```

4. **Esquema base (tabla orders PLANA, sin índices de optimización)**:
   ```bash
   export PGPASSWORD=ecommify
   DB="postgresql://ecommify:ecommify@localhost:5433/ecommify"
   psql "$DB" -v ON_ERROR_STOP=1 -f sql/00_schema_baseline.sql
   ```

5. **Carga masiva + VACUUM ANALYZE + reporte de volúmenes**:
   ```bash
   psql "$DB" -v ON_ERROR_STOP=1 -f sql/00_load.sql
   ```
   > Se usa la imagen multi‑arquitectura `imresamu/postgis:16-3.4` (mismo Dockerfile que `postgis/postgis`), que corre **nativa en arm64 y amd64** sin emulación. La carga completa toma aproximadamente 30 segundos.

6. **Aplicar optimizaciones**:
   Ejecuta los scripts SQL contenidos en la carpeta `sql/` para medir el impacto de las optimizaciones:
   - [01_critical_queries.sql](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/sql/01_critical_queries.sql): Ejecuta el baseline de consultas críticas.
   - [02_query_optimizations.sql](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/sql/02_query_optimizations.sql): Reescribe consultas OLTP críticas para mejorar performance.
   - [03_specialized_indexes.sql](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/sql/03_specialized_indexes.sql): Añade índices compuestos, parciales y GIN.
   - [04_partitioning.sql](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/sql/04_partitioning.sql): Implementa particionamiento por mes para las órdenes.

---

## 📂 Estructura del Módulo

```text
postgresql/optimizaciones/
├── docker-compose.yml          # PostgreSQL 16 + PostGIS, puerto host 5433
├── generate_data.py            # Generador de datos sintéticos a escala
├── README.md                   # Esta guía del módulo
├── REPORTE.md                  # Informe consolidado con planes EXPLAIN ANALYZE
├── Actividad 4 - Informe Optimizacion.pdf # Reporte formal en formato PDF
├── sql/                        # Directorio con scripts SQL de prueba
│   ├── 00_schema_baseline.sql  # Esquema base (plano, sin índices extra)
│   ├── 00_load.sql             # Carga masiva \copy + post-proceso
│   ├── 01_critical_queries.sql # Fase 1 — consultas OLTP críticas
│   ├── 02_query_optimizations.sql # Fase 2 — consultas optimizadas
│   ├── 03_specialized_indexes.sql # Fase 3 — índices especializados
│   └── 04_partitioning.sql     # Fase 4 — particionamiento declarativo
└── results/                    # Salidas EXPLAIN capturadas
    ├── 00_load.txt
    ├── 01_baseline_plans.txt
    ├── 02_optimizations.txt
    ├── 03_indexes.txt
    ├── 03b_gin_orders.txt
    └── 04_partitioning.txt
```

---

## 📊 Estado del Dataset Cargado

| Tabla | Filas | Notas para las fases |
|---|---:|---|
| `orders` | 1.000.000 | Rango 2016‑09 … 2018‑10 + 1.000 filas en 2019 (→ partición `DEFAULT`) |
| `order_items` | 1.489.352 | Claves foráneas a products (32 K) y sellers (3 K) |
| `order_payments` | 1.120.365 | Mezcla realista de medios de pago |
| `order_reviews` | 610.215 | Puntajes sesgados a 4‑5 |
| `customers` | 1.000.000 | 496 K personas; 297 K con >1 orden |
| `outbox_events` | 50.000 | 1.035 sin procesar (~2 %) → probado con índice parcial |
| `product_promotions` | 6.000 | 2.000 activas en `now()` |
