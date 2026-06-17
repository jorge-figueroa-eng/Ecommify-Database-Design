-- 02_types.sql
DO $$
BEGIN
  CREATE TYPE order_status_enum AS ENUM (
    'created','approved','invoiced','processing','shipped','delivered','canceled','unavailable'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE payment_type_enum AS ENUM (
    'credit_card','boleto','voucher','debit_card','not_defined'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE DOMAIN br_state AS CHAR(2)
CHECK (VALUE ~ '^[A-Z]{2}$');

DO $$
BEGIN
  CREATE TYPE address_br AS (
    zip_code_prefix INT,
    city TEXT,
    state CHAR(2)
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
