# Archivos corregidos para completar la rúbrica

Este ZIP contiene solamente archivos para reemplazar o agregar en el repositorio `Ecommify-Database-Design`.

## Archivos corregidos

| Archivo | Acción | Motivo |
|---|---|---|
| `postgresql/schema_final/01_extensions.sql` | Reemplazar | Los `CREATE EXTENSION` estaban después de un comentario `--` en la misma línea y podían no ejecutarse. |
| `postgresql/schema_final/02_types.sql` | Reemplazar | El archivo estaba en una línea comentada; además se hizo idempotente. |
| `postgresql/schema_final/05_constraints.sql` | Reemplazar | Se hizo idempotente para evitar errores al reejecutar. |
| `postgresql/schema_final/06_indexes.sql` | Reemplazar | Algunos índices podían quedar comentados; ahora cada índice está separado y documentado. |
| `postgresql/supabase/run_all_supabase.sql` | Reemplazar | El script maestro estaba comentado y no ejecutaba los `\i`. |
| `requirements.txt` | Agregar en raíz | El README lo menciona, pero no aparecía en la raíz del repositorio. |
| `actividad5/DOCUMENTO_TECNICO.md` | Reemplazar | Se unificaron nombres reales de colecciones MongoDB y rutas del repositorio. |
| `evidences/postgresql/postgresql_metrics.csv` | Reemplazar | El CSV estaba en una sola línea; ahora tiene filas separadas para diligenciar evidencia real. |
| `evidences/mongodb/mongodb_metrics.csv` | Reemplazar | El CSV estaba en una sola línea; ahora tiene filas separadas para diligenciar evidencia real. |
| `docs/video_link.md` | Agregar | Permite dejar evidencia del video exigido por la Etapa 2. |
| `docs/paso_a_paso_evidencias.md` | Agregar | Guía operativa para capturar evidencias cuantitativas. |

## Comando de reemplazo sugerido

Desde la raíz del repositorio local:

```bash
unzip Ecommify_archivos_corregidos_rubrica.zip -d /tmp/ecommify_fix
cp -R /tmp/ecommify_fix/ecommify_archivos_corregidos/* .
```

Luego subir a GitHub:

```bash
git add .
git commit -m "Fix Etapa 2 reproducibility and evidence files"
git push
```
