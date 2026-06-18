-- 02_types.sql
-- Tipos nativos avanzados, dominios y tipos compuestos para el esquema final.
-- El script es idempotente: puede ejecutarse más de una vez sin fallar por tipos existentes.

DO $$
BEGIN
    CREATE TYPE order_status_enum AS ENUM (
        'created',
        'approved',
        'invoiced',
        'processing',
        'shipped',
        'delivered',
        'canceled',
        'unavailable'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE payment_type_enum AS ENUM (
        'credit_card',
        'boleto',
        'voucher',
        'debit_card',
        'not_defined'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'br_state'
          AND n.nspname = current_schema()
    ) THEN
        CREATE DOMAIN br_state AS CHAR(2)
        CHECK (VALUE ~ '^[A-Z]{2}$');
    END IF;
END $$;

DO $$
BEGIN
    CREATE TYPE address_br AS (
        zip_code_prefix INT,
        city TEXT,
        state CHAR(2)
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
