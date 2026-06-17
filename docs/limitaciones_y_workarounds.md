# Limitaciones y workarounds

| Limitacion | Impacto | Workaround |
|---|---|---|
| Free tier de MongoDB Atlas no permite sharding real | No se puede desplegar cluster sharded real | Entregar diseno teorico y simulacion de distribucion |
| Carga de CSV grandes por SQL editor puede fallar | Timeouts o errores de memoria | Usar Colab/Python por lotes |
| Falta de `order_items` en los archivos cargados aqui | No se calculan ventas reales por producto-vendedor | Cargar archivo desde repositorio si existe o declarar alcance |
| Metricas dependen del cluster real | No se deben inventar tiempos | Ejecutar scripts y registrar resultados reales |
| `validationAction: error` puede bloquear carga por datos sucios | Fallo de ingesta | Usar `warn` durante carga inicial y endurecer despues |
