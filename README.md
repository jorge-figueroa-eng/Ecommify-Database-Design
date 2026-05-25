# Plantilla inicial proyecto Ecommify

## Arquitectura seleccionada
**Opción 3: Arquitectura Políglota Híbrida**

- PostgreSQL: datos estructurados, transaccionales y relacionales.
- MongoDB: datos semi-estructurados, catálogo flexible, reseñas agregadas, comportamiento de usuario y vistas documentales.

## Estructura

```text
Ecommify_Database_Design_Hibrida/
├── README.md
├── docs/
│   ├── Documento_Tecnico_Diseno_Hibrido.docx
│   ├── Documento_Tecnico_Diseno_Hibrido.pdf
│   ├── Presentacion_Ejecutiva_Hibrida.pptx
│   ├── Presentacion_Ejecutiva_Hibrida.pdf
│   ├── Extensiones_PostgreSQL_Ecommify.md
│   └── diagramas/
├── postgresql/
│   ├── schema/
│   ├── seed_data/
│   └── queries/
├── mongodb/
│   └── schema/
└── notebooks/
    └── Data_Exploration_Analysis.ipynb
```
