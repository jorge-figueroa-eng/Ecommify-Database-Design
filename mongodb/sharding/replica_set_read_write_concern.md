# Replica set y estrategias Read/Write Concern

## Topología propuesta

- Nodo 1: Primary
- Nodo 2: Secondary
- Nodo 3: Secondary

## Distribución geográfica sugerida

- Primary en región principal de operación.
- Secondary 1 en la misma región para baja latencia.
- Secondary 2 en región alternativa para tolerancia a fallos.

## Estrategias por operación

| Operación | Read Concern | Write Concern | Justificación |
|---|---|---|---|
| Carga histórica CSV | local | w:1 | Prioriza velocidad de importación. |
| Registro de orden nueva | majority | majority | Requiere consistencia transaccional. |
| Pagos | majority | majority | Información crítica del negocio. |
| Dashboard analítico | local | No aplica | Prioriza baja latencia. |
| Reviews | local | w:1 | Escritura de menor criticidad. |
| Conciliación financiera | majority | majority | Debe leer datos confirmados. |
