# Módulo de Optimización PostgreSQL para Ecommify (Supabase)

Este módulo contiene los scripts de prueba de rendimiento, reescritura de consultas, indexación especializada y particionamiento declarativo ejecutados directamente sobre **Supabase (PostgreSQL 17.6 + PostGIS)**.

Todas las dependencias de contenedores locales (Docker) han sido removidas, orientando toda la arquitectura y validación a la nube.

---

## 🛠️ Resumen de Optimizaciones Logradas en Supabase

| Tipo de Optimización | Consulta / Técnica | Latencia Inicial (Baseline) | Latencia Optimizada | Factor de Mejora | Impacto Técnico |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Optimización de Consulta** | OPT-3 (Anti-join `NOT EXISTS` vs `NOT IN`) | `3195.64 ms` | `35.42 ms` | **90.2x** | Evita derrame en disco por hash temporal |
| **Paginación Keyset** | OPT-4 (Cursor de ID vs `OFFSET` profundo) | `290.07 ms` | `0.09 ms` | **3223.0x** | Complejidad de acceso constante $O(1)$ |
| **Índice Compuesto** | IDX-2 (Seller Items recientes por timestamp) | `1206.58 ms` | `11.06 ms` | **109.1x** | Satisface filtro y orden, evitando el `Sort` |
| **Índice Parcial** | IDX-4 (Pedidos creados pendientes de aprobar) | `380.66 ms` | `1.52 ms` | **250.4x** | Índice ultraligero (~16 KB) para cola activa |
| **Índice BRIN** | IDX-7 (Rango temporal en serie de tiempo) | `17.97 ms` (B-tree) | `1.88 ms` (BRIN) | **9.5x** | Espacio reducido **655 veces** vs B-tree |
| **Particionamiento Rango**| Poda Mensual (`orders` vs `orders_part`) | `748.82 ms` | `2.38 ms` | **314.6x** | Poda 25 de 26 particiones en planificación |

> [!TIP]
> Para ver el análisis profundo de los planes de ejecución, tamaños físicos de índices, y trade-offs detallados, consulta el informe completo en **[REPORTE.md](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/optimizaciones/REPORTE.md)**.

---

## 📊 Carga Masiva y Escala de Datos en Supabase

Para cumplir con el límite de almacenamiento de **500 MB** de la capa gratuita de Supabase, escalamos la generación de datos a **150.000 órdenes transaccionales** (generando ~120 MB de datos en CSV y ocupando **~200 MB** de espacio indexado dentro de la base de datos). Esto es estadísticamente representativo de un entorno productivo sin saturar la cuota gratuita.

El volumen cargado se distribuye de la siguiente manera:
* `order_items`: 223,405 filas (60 MB)
* `order_payments`: 168,065 filas (33 MB)
* `customers`: 150,000 filas (30 MB)
* `orders`: 150,000 filas (44 MB)
* `order_reviews`: 91,677 filas (25 MB)
* `outbox_events`: 10,000 filas (2048 KB)

---

## ⚙️ Cómo Reproducir el Proceso de Optimización

### 1. Configurar la Conexión de Supabase
Crea un archivo llamado `.env` en la raíz del repositorio (`Ecommify-Database-Design/.env`) que contenga tu URI de conexión de Supabase. Dado que las contraseñas de base de datos pueden contener caracteres especiales como `@` o `:`, la contraseña del URI debe estar **URL-encoded** (ejemplo: `@` se reemplaza por `%40`).

```text
SUPABASE_DB_URL=postgresql://postgres.[PROYECTO]:[PASSWORD_URL_ENCODED]@aws-1-us-east-1.pooler.supabase.com:6543/postgres
```

### 2. Generar el Dataset Sintético
Navega a esta carpeta y ejecuta el generador de datos apuntando al directorio de semillas del repositorio:
```bash
cd postgresql/optimizaciones
python generate_data.py --orders 150000 --products 8000 --sellers 1000 --promos 1000 --outbox 10000 --seed-dir ../seed_data
```
Esto creará los archivos CSV en la subcarpeta `data/`.

### 3. Ejecutar la Limpieza y Despliegue del Esquema Base
Utiliza el script de utilidad Python para limpiar la base de datos Supabase e instalar el esquema inicial plano (sin índices adicionales ni particiones):
```bash
python run_sql_on_supabase.py sql/00_cleanup.sql
python run_sql_on_supabase.py sql/00_schema_baseline.sql
```

### 4. Cargar los Datos vía Streaming de Red
Ejecuta la carga masiva. Este comando utiliza `psql` con sentencias `\copy` para realizar la inserción a través de la red (no requiere que el servidor Supabase tenga acceso local a los archivos CSV):
```bash
python run_sql_on_supabase.py sql/00_load.sql
```
*(Tarda aproximadamente de 30 a 60 segundos según tu velocidad de conexión).*

### 5. Ejecutar la Suite de Benchmarks y Capturar Resultados
Ejecuta el script master que corre secuencialmente todas las pruebas de optimización, indexación y particionamiento, capturando los resultados `EXPLAIN ANALYZE` directamente en archivos de texto dentro de `results/`:
```bash
python ../../scratch/run_all_benchmarks.py
```

### 6. Regenerar los Gráficos de Rendimiento (Opcional)
Para redibujar las gráficas de rendimiento SVG basadas en tus propias latencias de red y hardware de Supabase:
```bash
python ../../scratch/generate_charts.py
```

---

## 📂 Estructura del Módulo

```text
postgresql/optimizaciones/
├── generate_data.py            # Generador de datos sintéticos
├── run_sql_on_supabase.py      # Utilidad Python para ejecutar SQL en Supabase
├── README.md                   # Esta guía de uso
├── REPORTE.md                  # Reporte detallado de optimizaciones y SVG gráficos
├── Actividad 4 - Informe Optimizacion.pdf # Reporte formal histórico
├── sql/                        # Carpeta de DDL y scripts SQL
│   ├── 00_cleanup.sql          # Elimina tablas/tipos previos para inicio limpio
│   ├── 00_schema_baseline.sql  # Esquema base (plano, sin índices extra)
│   ├── 00_load.sql             # Carga masiva \copy + post-proceso
│   ├── 01_critical_queries.sql # Fase 1 — consultas OLTP críticas base
│   ├── 02_query_optimizations.sql # Fase 2 — consultas optimizadas (reescrituras)
│   ├── 03_specialized_indexes.sql # Fase 3 — índices especializados (creación y EXPLAIN)
│   └── 04_partitioning.sql     # Fase 4 — particionamiento mensual y validación de poda
└── results/                    # Salidas EXPLAIN y gráficos de rendimiento
    ├── 01_baseline_plans.txt
    ├── 02_optimizations.txt
    ├── 03_indexes.txt
    ├── 04_partitioning.txt
    ├── query_optimizations_chart.svg
    ├── indexes_chart.svg
    └── partitioning_chart.svg
```
