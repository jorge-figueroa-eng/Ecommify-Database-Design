* Optimización de consultas mediante análisis de planes de ejecución:
    * Identificar entre 5 y 10 consultas críticas basándose en frecuencia de ejecución, tiempo de respuesta o impacto en el negocio.
    * Documentar el plan de ejecución antes de optimización usando EXPLAIN (ANALYZE, BUFFERS) para cada consulta crítica.
    * Aplicar al menos 3 tipos diferentes de optimización (puede incluir: reescritura de subconsultas, optimización de JOINs, uso de CTEs, eliminación de funciones en WHERE, etc.).
    * Documentar el plan de ejecución después de optimización
    * Reportar mejora cuantificable: porcentaje de reducción en tiempo de ejecución y/o porcentaje de reducción en bloques leídos.
**Nota:** las técnicas específicas de optimización quedan a criterio del equipo según las características de sus consultas. La documentación debe justificar por qué cada optimización era apropiada para ese caso específico.

* Creación de índices especializados:
    * Implementar al menos 3 tipos diferentes de índices (seleccionar según necesidad de: B-tree simple, B-tree compuesto, GIN, GiST, BRIN, Hash, parciales, de expresión, etc.).
    * Documentar para cada índice:
        * Tipo de índice seleccionado.
        * Justificación técnica de selección (¿por qué ese tipo para ese caso?).
        * Patrón de consulta que optimiza.
        * Trade-offs considerados (espacio vs velocidad, mantenimiento).
    * Medir impacto cuantitativo:
        * Tiempo de ejecución antes/después para consultas relevantes.
        * Tamaño del índice creado.
        * Diferencia en plan de ejecución (Seq Scan vs Index Scan).

* Aplicación de particionamiento declarativo:
    * Análisis y selección:
        * Identificar tablas candidatas (criterio sugerido: >100,000 registros).
        * Analizar patrones de consulta para identificar columnas frecuentemente usadas en filtros WHERE.
        * Seleccionar tabla y columna de partición justificando la decisión.
        * Determinar tipo de particionamiento apropiado (RANGE, LIST o HASH) según el caso de uso.
    * Diseño de estrategia:
        * Definir granularidad de particiones (por ejemplo: mensual, trimestral, por región, etc.).
        * Diseñar esquema de particiones incluyendo partición DEFAULT.
        * Documentar estrategia de creación automática de nuevas particiones si aplica.
    * Implementación y validación:
        * Crear la tabla particionada y sus particiones.
        * Migrar datos existentes (si aplica).
        * Comparar rendimiento entre escenarios con y sin particionamiento.
        * Documentar mejoras observadas con métricas cuantificables.