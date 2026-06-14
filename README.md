# Ecommify Database Design & Optimization (Arquitectura Híbrida Políglota)

Este repositorio contiene el diseño lógico y físico de la base de datos para **Ecommify**, un sistema de comercio electrónico a gran escala. La solución adopta una **Arquitectura Políglota Híbrida** combinando **PostgreSQL 16 (con PostGIS)** para el procesamiento transaccional y relacional estructurado, y **MongoDB** para almacenar datos semi-estructurados y flujos ágiles.

---

## 🏗️ Arquitectura de la Solución

La base de datos está dividida funcionalmente según la naturaleza y acceso a los datos:

```mermaid
graph TD
    Client[Ecommify Application Client] --> PostgreSQL[(PostgreSQL 16 + PostGIS)]
    Client --> MongoDB[(MongoDB)]

    subgraph PostgreSQL [Módulo Relacional y Transaccional]
        geo_locations[geo_locations - PostGIS]
        customers[customers]
        sellers[sellers]
        orders[orders - Particionamiento Rango]
        order_items[order_items]
        order_payments[order_payments]
        outbox[outbox_events]
    end

    subgraph MongoDB [Módulo Documental y Flexible]
        catalog[catalogo_enriquecido]
        behavior[customer_behavior]
        metrics[seller_metrics]
        reviews[order_reviews]
    end

    orders --> customers
    orders --> order_items
    order_items --> sellers
    customers --> geo_locations
    sellers --> geo_locations
```

### 🗄️ PostgreSQL (Módulo Transaccional)
* **Propósito**: Consistencia ACID, integridad referencial estricta y transacciones complejas.
* **Componentes**:
  * **Datos Core**: Clientes, vendedores, órdenes, pagos y geolocalizaciones.
  * **PostGIS**: Consultas geográficas y cálculo de distancias reales de entrega.
  * **Tipos Avanzados**: Atributos en formato `JSONB`, tokens en `ARRAY` y soporte para búsquedas tipográficas tolerantes mediante `pg_trgm`.
  * **Particionamiento**: Particionamiento declarativo por rango en la tabla histórica de órdenes para mantener la eficiencia ante millones de filas.

### 🍃 MongoDB (Módulo Documental)
* **Propósito**: Alta velocidad de lectura, flexibilidad de esquema y persistencia de interacciones del usuario.
* **Componentes**:
  * **Catálogo Enriquecido**: Atributos técnicos altamente dinámicos y traducciones del catálogo de productos.
  * **Comportamiento del Usuario**: Logs de navegación y eventos del cliente.
  * **Métricas de Vendedor**: Agregaciones históricas rápidas de ventas y calificaciones.
  * **Reseñas**: Almacenamiento rápido de comentarios con estructuras anidadas.

---

## 📂 Estructura del Repositorio

El proyecto está organizado en las siguientes carpetas:

```text
Ecommify-Database-Design/
├── README.md                           # Guía general de la arquitectura y el repositorio
├── postgresql/                         # Recursos para PostgreSQL
│   ├── schema/                         # Scripts DDL de inicialización
│   │   ├── 01_extensions.sql           # Carga de extensiones (PostGIS, pg_trgm, etc.)
│   │   ├── 01_customers.sql            # Tabla de clientes y snapshot geográfico
│   │   ├── 02_schema_hibrido.sql       # Tablas principales (orders, products, geo_locations...)
│   │   ├── 02_sellers.sql              # Tabla de vendedores y tags de capacidades
│   │   ├── 03_orders.sql               # Tabla base de órdenes
│   │   ├── 03_partitions_and_mviews.sql # Vistas materializadas de agregados mensuales y segmentos
│   │   ├── 04_order_items.sql          # Tabla de ítems incluidos en las órdenes
│   │   ├── 05_order_payments.sql       # Tabla de desglose de pagos por orden
│   │   └── 06_index_creation.sql       # Índices relacionales base
│   ├── seed_data/                      # Semillas CSV base para desarrollo (~200 filas por archivo)
│   │   ├── categories.csv
│   │   ├── customers.csv
│   │   ├── geolocation.csv
│   │   ├── orders.csv
│   │   ├── order_items.csv
│   │   ├── payments.csv
│   │   ├── products.csv
│   │   ├── reviews.csv
│   │   └── sellers.csv
│   └── queries/                        # Consultas avanzadas y mantenimiento
│       ├── advanced_types.sql          # Consultas para JSONB, Arrays, Rangos y PostGIS
│       └── maintenance_jobs.sql        # Estrategia de VACUUM y refresco de vistas
├── mongodb/                            # Recursos para MongoDB
│   └── schema/                         # Esquemas JSON para validación documental
│       ├── 01_catalogo_enriquecido_schema.json
│       ├── 02_customer_behavior_schema.json
│       ├── 03_seller_metrics_schema.json
│       └── 04_order_reviews_schema.json
├── notebooks/                          # Análisis exploratorio y pruebas en Python
│   └── Data_Exploration_Analysis.ipynb
└── actividad4/                         # Tarea de Optimización y Rendimiento (1.000.000 de órdenes)
    ├── docker-compose.yml              # Contenedor local con PostgreSQL 16 + PostGIS
    ├── generate_data.py                # Generador de datos sintéticos a gran escala
    ├── README.md                       # Guía específica para reproducir las optimizaciones
    ├── REPORTE.md                      # Informe detallado de optimizaciones y métricas EXPLAIN ANALYZE
    ├── Actividad 4 - Informe Optimizacion.pdf # Reporte formal en formato PDF
    ├── sql/                            # Scripts SQL de optimización, índices y particionamiento
    │   ├── 00_schema_baseline.sql      # Esquema inicial plano sin optimizaciones
    │   ├── 00_load.sql                 # Carga masiva de datos sintéticos generados
    │   ├── 01_critical_queries.sql     # Consultas OLTP críticas bajo análisis
    │   ├── 02_query_optimizations.sql  # Reescritura y optimización de consultas
    │   ├── 03_specialized_indexes.sql  # Creación de índices parciales, compuestos y GIN
    │   └── 04_partitioning.sql         # Particionamiento declarativo por mes
    └── results/                        # Logs de ejecución y planes EXPLAIN del análisis
        ├── 00_load.txt
        ├── 01_baseline_plans.txt
        ├── 02_optimizations.txt
        ├── 03_indexes.txt
        ├── 03b_gin_orders.txt
        └── 04_partitioning.txt
```

---

## ⚙️ Guía de Inicio Rápido

> [!NOTE]
> Para la carga básica de desarrollo relacional, puedes importar los CSV ubicados en [postgresql/seed_data/](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/seed_data/) directamente en tu instancia de base de datos Postgres una vez ejecutados los archivos en [postgresql/schema/](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/postgresql/schema/).

### ⚡ Reproducción de Actividad de Rendimiento y Optimización (Escala 1M órdenes)

Para ejecutar las pruebas de carga a gran escala con un dataset sintético realista de **1 millón de órdenes** y analizar los planes de optimización de consultas (`EXPLAIN ANALYZE`), sigue los pasos descritos en la carpeta de rendimiento:

1. **Navegar a la carpeta del módulo de optimización**:
   ```bash
   cd actividad4
   ```

2. **Levantar la base de datos aislada con Docker Compose**:
   ```bash
   docker compose up -d
   ```

3. **Generar los datos sintéticos basados en distribuciones reales**:
   Generará alrededor de 780 MB de archivos CSV con distribuciones estadísticas de ventas realistas.
   ```bash
   python generate_data.py --orders 1000000
   ```

4. **Ejecutar el esquema inicial de prueba y cargar los datos**:
   ```bash
   psql "postgresql://ecommify:ecommify@localhost:5433/ecommify" -f sql/00_schema_baseline.sql
   psql "postgresql://ecommify:ecommify@localhost:5433/ecommify" -f sql/00_load.sql
   ```

5. **Aplicar las optimizaciones paso a paso**:
   Revisa los archivos bajo [actividad4/sql/](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/actividad4/sql/) para comprender las optimizaciones de consultas y particionamiento, y consulta el reporte detallado en [actividad4/REPORTE.md](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/actividad4/REPORTE.md).

---

## 🛠️ Resumen de Optimizaciones Logradas (Módulo Actividad 4)

| Tipo de Optimización | Consulta Bajo Análisis | Latencia Inicial (Baseline) | Latencia Optimizada | Factor de Mejora |
|---|---|---|---|---|
| **Optimización de Consulta** | Q3 (Búsqueda de Vendedores con Geolocalización) | `611.23 ms` | `37.26 ms` | **16.4x** |
| **Índice Compuesto** | Q4 (Órdenes Entregadas con Retraso) | `84.81 ms` | `2.13 ms` | **39.8x** |
| **Índice Parcial** | Q8 (Procesamiento de Outbox Cola Activa) | `10.22 ms` | `0.04 ms` | **255.5x** |
| **Índice GIN (JSONB)** | Q6 (Búsqueda de Especificaciones de Productos) | `372.10 ms` | `0.11 ms` | **3382.7x** |
| **Particionamiento Rango** | Q9 (Volumen mensual histórico por canal de pago) | `265.81 ms` | `10.21 ms` (Partition Pruning) | **26.0x** |

Para ver el análisis profundo de cada plan de ejecución con las métricas detalladas de lectura en disco y búferes, consulta el informe en [actividad4/REPORTE.md](file:///D:/Workspaces/source/repos/Ecommify-Database-Design/actividad4/REPORTE.md).
