-- 03_tables.sql
-- Esquema relacional completo para Supabase/PostgreSQL.

CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix INTEGER NOT NULL,
    customer_city TEXT NOT NULL,
    customer_state br_state NOT NULL,
    customer_address address_br,
    customer_tags TEXT[] NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_customer_city_not_empty CHECK (length(trim(customer_city)) > 0)
);

CREATE TABLE IF NOT EXISTS geolocations (
    geolocation_id BIGSERIAL PRIMARY KEY,
    geolocation_zip_code_prefix INTEGER NOT NULL,
    geolocation_lat DOUBLE PRECISION NOT NULL,
    geolocation_lng DOUBLE PRECISION NOT NULL,
    geolocation_city TEXT NOT NULL,
    geolocation_state br_state NOT NULL,
    city_aliases TEXT[] NOT NULL DEFAULT '{}',
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    geom GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(geolocation_lng, geolocation_lat), 4326)::geography
    ) STORED,
    CONSTRAINT chk_latitude CHECK (geolocation_lat BETWEEN -90 AND 90),
    CONSTRAINT chk_longitude CHECK (geolocation_lng BETWEEN -180 AND 180)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER NOT NULL,
    seller_city TEXT NOT NULL,
    seller_state br_state NOT NULL,
    seller_tags TEXT[] NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS product_categories (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT,
    search_tokens TEXT[] NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT REFERENCES product_categories(product_category_name),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,
    dimensions JSONB GENERATED ALWAYS AS (
        jsonb_build_object(
            'weight_g', product_weight_g,
            'length_cm', product_length_cm,
            'height_cm', product_height_cm,
            'width_cm', product_width_cm,
            'volume_cm3', COALESCE(product_length_cm, 0) * COALESCE(product_height_cm, 0) * COALESCE(product_width_cm, 0)
        )
    ) STORED,
    attributes JSONB NOT NULL DEFAULT '[]'::jsonb,
    product_tags TEXT[] NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT chk_product_dimensions_non_negative CHECK (
        COALESCE(product_weight_g, 0) >= 0 AND
        COALESCE(product_length_cm, 0) >= 0 AND
        COALESCE(product_height_cm, 0) >= 0 AND
        COALESCE(product_width_cm, 0) >= 0
    )
);

CREATE TABLE IF NOT EXISTS orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id),
    order_status order_status_enum NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_approved_at TIMESTAMPTZ,
    order_delivered_carrier_date TIMESTAMPTZ,
    order_delivered_customer_date TIMESTAMPTZ,
    order_estimated_delivery_date TIMESTAMPTZ,
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT chk_order_dates CHECK (
        order_approved_at IS NULL OR order_approved_at >= order_purchase_timestamp
    )
);

-- Tabla particionada para análisis temporal y pruning de particiones.
CREATE TABLE IF NOT EXISTS orders_part (
    order_id TEXT NOT NULL,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id),
    order_status order_status_enum NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_approved_at TIMESTAMPTZ,
    order_delivered_carrier_date TIMESTAMPTZ,
    order_delivered_customer_date TIMESTAMPTZ,
    order_estimated_delivery_date TIMESTAMPTZ,
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, order_purchase_timestamp)
) PARTITION BY RANGE (order_purchase_timestamp);

CREATE TABLE IF NOT EXISTS order_items (
    order_id TEXT NOT NULL REFERENCES orders(order_id),
    order_item_id INTEGER NOT NULL,
    product_id TEXT NOT NULL REFERENCES products(product_id),
    seller_id TEXT NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMPTZ,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    freight_value NUMERIC(12,2) NOT NULL CHECK (freight_value >= 0),
    item_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id TEXT NOT NULL REFERENCES orders(order_id),
    payment_sequential INTEGER NOT NULL,
    payment_type payment_type_enum NOT NULL,
    payment_installments INTEGER NOT NULL CHECK (payment_installments >= 0),
    payment_value NUMERIC(12,2) NOT NULL CHECK (payment_value >= 0),
    payment_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(order_id),
    review_score INTEGER NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMPTZ,
    review_answer_timestamp TIMESTAMPTZ,
    review_tags TEXT[] NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS outbox_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    retries INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT chk_retries_non_negative CHECK (retries >= 0)
);
