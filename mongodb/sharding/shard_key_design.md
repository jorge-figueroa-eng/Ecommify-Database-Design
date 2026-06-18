# Diseño teórico de sharding - Ecommify

## Colección candidata

`orders_analytics`

## Shard key propuesta

```javascript
{ "customer.state": 1, "purchase_year_month": 1, "order_id": "hashed" }
```

## Justificación

- `customer.state` permite direccionar consultas analíticas regionales.
- `purchase_year_month` permite segmentar por ventana temporal.
- `order_id` con hash reduce riesgo de concentración cuando estados de alto volumen, como SP, concentran gran parte de las órdenes.

## Riesgo mitigado

Usar solo `customer.state` generaría skew, porque la distribución de órdenes no es uniforme entre estados. El componente temporal y el hash de `order_id` aumentan la cardinalidad y distribuyen escrituras/lecturas.

## Comando teórico

```javascript
sh.enableSharding("ecommify")
sh.shardCollection(
  "ecommify.orders_analytics",
  { "customer.state": 1, "purchase_year_month": 1, "order_id": "hashed" }
)
```
