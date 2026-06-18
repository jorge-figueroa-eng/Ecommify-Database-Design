-- 05_constraints.sql
-- Constraints adicionales y validaciones semánticas.
-- Script idempotente para evitar errores si ya existen las restricciones.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'uq_order_payment_sequence'
    ) THEN
        ALTER TABLE order_payments
        ADD CONSTRAINT uq_order_payment_sequence
        UNIQUE (order_id, payment_sequential);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_review_answer_after_creation'
    ) THEN
        ALTER TABLE order_reviews
        ADD CONSTRAINT chk_review_answer_after_creation
        CHECK (
            review_answer_timestamp IS NULL
            OR review_creation_date IS NULL
            OR review_answer_timestamp >= review_creation_date
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_product_dimensions_non_negative'
    ) THEN
        ALTER TABLE products
        ADD CONSTRAINT chk_product_dimensions_non_negative
        CHECK (
            (product_length_cm IS NULL OR product_length_cm >= 0)
            AND (product_height_cm IS NULL OR product_height_cm >= 0)
            AND (product_width_cm IS NULL OR product_width_cm >= 0)
        );
    END IF;
END $$;
