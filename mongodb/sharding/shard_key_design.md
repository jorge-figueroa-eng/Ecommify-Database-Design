# Diseno teorico de sharding para Ecommify

## Coleccion candidata

`orders_analytics`, porque concentra consultas por estado, fecha, estado de orden y resumen de pagos.

## Shard key propuesta

```javascript
{ "customer.state": 1, "purchase_year_month": 1, "order_id": "hashed" }
```

## Justificacion tecnica

- `customer.state`: soporta consultas regionales frecuentes.
- `purchase_year_month`: soporta ventanas temporales y dashboards mensuales.
- `order_id hashed`: reduce el riesgo de concentracion en estados con alto volumen como SP.

## Riesgo de shard key simple

Si se usa solo `customer.state`, SP concentra 41,746 ordenes del dataset cargado, por lo que puede generar skew.

## Simulacion de distribucion con hash de order_id en 3 shards

| Shard | Ordenes | Porcentaje |
|---|---:|---:|
| Shard 0 | 33,283 | 33.47% |
| Shard 1 | 33,225 | 33.41% |
| Shard 2 | 32,933 | 33.12% |

La distribucion queda cercana a 33% por shard, por lo que el componente hash ayuda a balancear.
