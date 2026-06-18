# Simulación de distribución de datos entre shards

La simulación debe ejecutarse sobre el dataset real usando hash de `order_id`.

## Estrategia

1. Tomar todos los `order_id`.
2. Calcular hash determinístico.
3. Asignar `hash(order_id) % 3` para tres shards.
4. Comparar conteo y porcentaje por shard.

## Interpretación esperada

Una distribución cercana a 33% / 33% / 33% indica balance aceptable. Si un shard supera de forma significativa a los demás, se debe ajustar la shard key.

## Script recomendado

Ver `scripts/simulate_shard_distribution.py`.
