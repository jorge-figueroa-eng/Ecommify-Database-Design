# Sincronizacion PostgreSQL - MongoDB

## Estrategia

Se implementa el patron Transactional Outbox.

## Flujo

1. PostgreSQL recibe la operacion transaccional.
2. La transaccion escribe en tablas relacionales y en `outbox_events`.
3. Un proceso worker consulta eventos pendientes.
4. El worker transforma la informacion al modelo documental.
5. MongoDB actualiza `orders_analytics`, `products_catalog`, `seller_state_buckets` u otra coleccion.
6. El evento se marca como `processed`.

## Consistencia

Se usa consistencia eventual. PostgreSQL es la fuente de verdad para datos transaccionales y MongoDB es una proyeccion analitica.

## Ventaja

Evita transacciones distribuidas y mantiene bajo acoplamiento entre motores.
