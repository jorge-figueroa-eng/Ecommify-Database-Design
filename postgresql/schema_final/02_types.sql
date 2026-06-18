-- 02_types.sql
-- Tipos nativos avanzados, dominios y enums.

CREATE DOMAIN br_state AS CHAR(2)
CHECK (VALUE IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'));

CREATE TYPE order_status_enum AS ENUM (
    'created',
    'approved',
    'invoiced',
    'processing',
    'shipped',
    'delivered',
    'unavailable',
    'canceled'
);

CREATE TYPE payment_type_enum AS ENUM (
    'credit_card',
    'boleto',
    'voucher',
    'debit_card',
    'not_defined'
);

CREATE TYPE address_br AS (
    zip_code_prefix INTEGER,
    city TEXT,
    state br_state
);
