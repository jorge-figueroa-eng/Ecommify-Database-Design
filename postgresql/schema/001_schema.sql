-- Ecommify Database Design - PostgreSQL/Supabase
-- Generado con base en los CSV reales de Olist cargados por el estudiante.
-- Arquitectura seleccionada: transaccional-analítica.
-- PostgreSQL: módulo OLTP, normalizado mínimo 3FN + tipos avanzados.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Dominio para estados de Brasil usados por el dataset.
CREATE DOMAIN brazil_state AS CHAR(2)
CHECK (VALUE ~ '^[A-Z]{2}$');

-- Tipos enumerados para datos operativos observados en el dataset.
DO $$ BEGIN
    CREATE TYPE order_status_enum AS ENUM (
        'created', 'approved', 'invoiced', 'processing',
        'shipped', 'delivered', 'unavailable', 'canceled'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_type_enum AS ENUM (
        'credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Tabla geográfica agregada por código postal.
-- El CSV geolocation no puede usarse directamente con zip_code_prefix como PK porque contiene múltiples coordenadas por prefijo.
CREATE TABLE IF NOT EXISTS geo_zip_summary (
    zip_code_prefix INTEGER PRIMARY KEY,
    city VARCHAR(120) NOT NULL,
    state brazil_state NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    location GEOGRAPHY(Point, 4326),
    source_points_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(40) PRIMARY KEY,
    customer_unique_id VARCHAR(40) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(120) NOT NULL,
    customer_state brazil_state NOT NULL,
    profile_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_customers_geo
        FOREIGN KEY (customer_zip_code_prefix)
        REFERENCES geo_zip_summary(zip_code_prefix)
        DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id VARCHAR(40) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(120) NOT NULL,
    seller_state brazil_state NOT NULL,
    location GEOGRAPHY(Point, 4326),
    seller_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_sellers_geo
        FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES geo_zip_summary(zip_code_prefix)
        DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE IF NOT EXISTS product_categories (
    product_category_name VARCHAR(120) PRIMARY KEY,
    product_category_name_english VARCHAR(120),
    synonyms TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    category_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(40) PRIMARY KEY,
    product_category_name VARCHAR(120),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,
    specifications JSONB NOT NULL DEFAULT '{}'::jsonb,
    search_terms TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_products_category
        FOREIGN KEY (product_category_name)
        REFERENCES product_categories(product_category_name)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT chk_product_weight CHECK (product_weight_g IS NULL OR product_weight_g >= 0),
    CONSTRAINT chk_product_dimensions CHECK (
        (product_length_cm IS NULL OR product_length_cm > 0) AND
        (product_height_cm IS NULL OR product_height_cm > 0) AND
        (product_width_cm IS NULL OR product_width_cm > 0)
    ),
    CONSTRAINT chk_product_photos CHECK (product_photos_qty IS NULL OR product_photos_qty >= 0)
);

-- Tabla particionada por fecha de compra para separar datos hot/cold.
CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(40) NOT NULL,
    customer_id VARCHAR(40) NOT NULL,
    order_status order_status_enum NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_approved_at TIMESTAMPTZ,
    order_delivered_carrier_date TIMESTAMPTZ,
    order_delivered_customer_date TIMESTAMPTZ,
    order_estimated_delivery_date TIMESTAMPTZ NOT NULL,
    fulfillment_period TSTZRANGE,
    status_history JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (order_id, order_purchase_timestamp),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT chk_fulfillment_range CHECK (
        fulfillment_period IS NULL OR lower(fulfillment_period) <= upper(fulfillment_period)
    )
) PARTITION BY RANGE (order_purchase_timestamp);

CREATE TABLE IF NOT EXISTS orders_2016 PARTITION OF orders
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE IF NOT EXISTS orders_2017 PARTITION OF orders
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE IF NOT EXISTS orders_2018 PARTITION OF orders
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE IF NOT EXISTS orders_future PARTITION OF orders
    FOR VALUES FROM ('2019-01-01') TO ('2030-01-01');

CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(40) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(40) NOT NULL,
    seller_id VARCHAR(40) NOT NULL,
    shipping_limit_date TIMESTAMPTZ NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    freight_value NUMERIC(12,2) NOT NULL,
    item_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id, order_purchase_timestamp)
        REFERENCES orders(order_id, order_purchase_timestamp),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    CONSTRAINT fk_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES sellers(seller_id),
    CONSTRAINT chk_order_item_price CHECK (price >= 0),
    CONSTRAINT chk_order_item_freight CHECK (freight_value >= 0)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id VARCHAR(40) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type payment_type_enum NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value NUMERIC(12,2) NOT NULL,
    payment_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_order_payments_order
        FOREIGN KEY (order_id, order_purchase_timestamp)
        REFERENCES orders(order_id, order_purchase_timestamp),
    CONSTRAINT chk_payment_installments CHECK (payment_installments >= 0),
    CONSTRAINT chk_payment_value CHECK (payment_value >= 0)
);

-- review_id no es único en el CSV real; por eso se agrega review_record_id como PK técnica.
CREATE TABLE IF NOT EXISTS order_reviews (
    review_record_id BIGSERIAL PRIMARY KEY,
    review_id VARCHAR(40) NOT NULL,
    order_id VARCHAR(40) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    review_score INTEGER NOT NULL,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMPTZ NOT NULL,
    review_answer_timestamp TIMESTAMPTZ NOT NULL,
    sentiment_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT fk_order_reviews_order
        FOREIGN KEY (order_id, order_purchase_timestamp)
        REFERENCES orders(order_id, order_purchase_timestamp),
    CONSTRAINT chk_review_score CHECK (review_score BETWEEN 1 AND 5)
);

CREATE TABLE IF NOT EXISTS promotions (
    promotion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id VARCHAR(40),
    promotion_name VARCHAR(180) NOT NULL,
    promotion_period TSTZRANGE NOT NULL,
    discount_percentage NUMERIC(5,2) NOT NULL,
    CONSTRAINT fk_promotions_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT chk_discount_percentage CHECK (discount_percentage >= 0 AND discount_percentage <= 100)
);

CREATE TABLE IF NOT EXISTS outbox_events (
    event_id BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(80) NOT NULL,
    aggregate_id VARCHAR(80) NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_sellers_updated_at BEFORE UPDATE ON sellers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Índices OLTP.
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_date ON orders(order_status, order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_seller ON order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_payments_type ON order_payments(payment_type);
CREATE INDEX IF NOT EXISTS idx_reviews_order ON order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_score ON order_reviews(review_score);

-- Índices avanzados.
CREATE INDEX IF NOT EXISTS idx_products_specs_gin ON products USING GIN (specifications jsonb_path_ops);
CREATE INDEX IF NOT EXISTS idx_products_search_terms_gin ON products USING GIN (search_terms);
CREATE INDEX IF NOT EXISTS idx_categories_trgm_en ON product_categories USING GIN (product_category_name_english gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_categories_trgm_pt ON product_categories USING GIN (product_category_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_geo_location_gist ON geo_zip_summary USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_sellers_location_gist ON sellers USING GIST (location);

-- Vistas materializadas OLAP.
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_sales_by_category_monthly AS
SELECT
    date_trunc('month', o.order_purchase_timestamp) AS month,
    p.product_category_name,
    pc.product_category_name_english,
    COUNT(DISTINCT o.order_id) AS orders_count,
    SUM(oi.price) AS gross_product_sales,
    SUM(oi.freight_value) AS freight_sales,
    SUM(oi.price + oi.freight_value) AS total_sales
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id AND oi.order_purchase_timestamp = o.order_purchase_timestamp
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN product_categories pc ON pc.product_category_name = p.product_category_name
GROUP BY 1, 2, 3;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_sales_by_category_monthly
ON mv_sales_by_category_monthly(month, product_category_name);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_customer_segments AS
SELECT
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(op.payment_value), 0) AS total_spent,
    CASE
        WHEN COALESCE(SUM(op.payment_value), 0) >= 1000 THEN 'HIGH_VALUE'
        WHEN COALESCE(SUM(op.payment_value), 0) >= 300 THEN 'MEDIUM_VALUE'
        ELSE 'LOW_VALUE'
    END AS segment
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_payments op ON op.order_id = o.order_id AND op.order_purchase_timestamp = o.order_purchase_timestamp
GROUP BY c.customer_unique_id, c.customer_state;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_customer_segments
ON mv_customer_segments(customer_unique_id);
