# Sincronización PostgreSQL → MongoDB

## Estrategia seleccionada

Se usa el patrón **Transactional Outbox**.

## Flujo

1. PostgreSQL registra la transacción principal en tablas relacionales.
2. En la misma transacción se inserta un evento en `outbox_events`.
3. Un worker lee eventos pendientes.
4. El worker transforma la información al modelo documental.
5. MongoDB actualiza `orders_analytics`, `products_catalog` o colecciones analíticas.
6. El evento queda marcado con `processed_at`.

## Tipo de consistencia

Se adopta **consistencia eventual**. PostgreSQL mantiene la fuente de verdad transaccional y MongoDB sirve consultas analíticas de baja latencia.

## Ventajas

- Evita transacciones distribuidas entre PostgreSQL y MongoDB.
- Permite reintentos controlados.
- Facilita auditoría por medio de `outbox_events`.
