# Replica set y estrategias Read/Write Concern

## Topologia teorica

```text
Replica Set rs-ecommify
├── Nodo 1: Primary - region principal
├── Nodo 2: Secondary - misma region o region cercana
└── Nodo 3: Secondary - region alterna para tolerancia a fallos
```

## Estrategias por operacion

| Operacion | Read Concern | Write Concern | Razon |
|---|---|---|---|
| Carga historica CSV | local | w:1 | Prioriza velocidad durante ingesta masiva. |
| Registro de pagos | majority | majority | Dato critico y financiero. |
| Ordenes nuevas | majority | majority | Requiere consistencia fuerte. |
| Dashboard analitico | local | no aplica | Lectura rapida y tolerante a pequena latencia. |
| Reviews | local | w:1 | Escritura no critica; eventual consistency aceptable. |
| Cierre/reportes | majority | majority | Requiere lectura consistente para indicadores finales. |
