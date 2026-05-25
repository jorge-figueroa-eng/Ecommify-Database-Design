-- 02_schema_hibrido.sql
-- Diseño relacional avanzado para el modulo estructurado de Ecommify en PostgreSQL.
-- Arquitectura seleccionada: Opcion 3 - Arquitectura Poliglota Hibrida.

CREATE TYPE address_br AS (
    zip_code_prefix INTEGER,
    city VARCHAR(120),
    state CHAR(2)
);

CREATE TYPE payment_method AS ENUM (
    'credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined'
);

CREATE TABLE categories (
    category_id BIGSERIAL PRIMARY KEY,
    name_pt VARCHAR(120) UNIQUE NOT NULL,
    name_en VARCHAR(120),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE geo_locations (
    zip_code_prefix INTEGER PRIMARY KEY,
    city VARCHAR(120) NOT NULL,
    state CHAR(2) NOT NULL,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    geo_point GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(120) NOT NULL,
    customer_state CHAR(2) NOT NULL,
    location_snapshot address_br,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT fk_customers_geo FOREIGN KEY (customer_zip_code_prefix)
        REFERENCES geo_locations(zip_code_prefix)
);

CREATE TABLE sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(120) NOT NULL,
    seller_state CHAR(2) NOT NULL,
    capability_tags TEXT[] DEFAULT '{}',
    location_snapshot address_br,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT fk_sellers_geo FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES geo_locations(zip_code_prefix)
);

CREATE TABLE products (
    product_id CHAR(32) PRIMARY KEY,
    category_id BIGINT REFERENCES categories(category_id),
    product_category_name VARCHAR(120),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,
    product_specifications JSONB NOT NULL DEFAULT '{}'::jsonb,
    product_photo_refs TEXT[] DEFAULT '{}',
    search_tokens TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT chk_product_weight_nonnegative CHECK (product_weight_g IS NULL OR product_weight_g >= 0),
    CONSTRAINT chk_product_dimensions_nonnegative CHECK (
        (product_length_cm IS NULL OR product_length_cm >= 0) AND
        (product_height_cm IS NULL OR product_height_cm >= 0) AND
        (product_width_cm IS NULL OR product_width_cm >= 0)
    )
);

CREATE TABLE orders (
    order_id CHAR(32) NOT NULL,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(40) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_approved_at TIMESTAMPTZ,
    order_delivered_carrier_date TIMESTAMPTZ,
    order_delivered_customer_date TIMESTAMPTZ,
    order_estimated_delivery_date TIMESTAMPTZ NOT NULL,
    shipping_address_snapshot address_br,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (order_id, order_purchase_timestamp),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT chk_order_status CHECK (order_status IN (
        'created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'unavailable', 'canceled'
    ))
) PARTITION BY RANGE (order_purchase_timestamp);

CREATE TABLE orders_2016 PARTITION OF orders
FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE orders_2017 PARTITION OF orders
FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE orders_2018 PARTITION OF orders
FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE order_items (
    order_id CHAR(32) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMPTZ NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    freight_value NUMERIC(12, 2) NOT NULL,
    item_attributes JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, order_purchase_timestamp, order_item_id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id, order_purchase_timestamp)
        REFERENCES orders(order_id, order_purchase_timestamp),
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_order_items_seller FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    CONSTRAINT chk_order_item_price CHECK (price >= 0),
    CONSTRAINT chk_order_item_freight CHECK (freight_value >= 0)
);

CREATE TABLE order_payments (
    order_id CHAR(32) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type payment_method NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value NUMERIC(12, 2) NOT NULL,
    payment_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (order_id, order_purchase_timestamp, payment_sequential),
    CONSTRAINT fk_order_payments_order FOREIGN KEY (order_id, order_purchase_timestamp)
        REFERENCES orders(order_id, order_purchase_timestamp),
    CONSTRAINT chk_payment_installments CHECK (payment_installments >= 0),
    CONSTRAINT chk_payment_value CHECK (payment_value >= 0)
);

CREATE TABLE order_reviews (
    review_id CHAR(32) NOT NULL,
    order_id CHAR(32) NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    review_score INTEGER NOT NULL,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMPTZ NOT NULL,
    review_answer_timestamp TIMESTAMPTZ NOT NULL,
    moderation_flags TEXT[] DEFAULT '{}',
    review_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (review_id, order_id),
    CONSTRAINT fk_order_reviews_order FOREIGN KEY (order_id, order_purchase_timestamp)
        REFERENCES orders(order_id, order_purchase_timestamp),
    CONSTRAINT chk_review_score CHECK (review_score BETWEEN 1 AND 5)
);

CREATE TABLE product_promotions (
    promotion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id CHAR(32) NOT NULL REFERENCES products(product_id),
    seller_id CHAR(32) REFERENCES sellers(seller_id),
    promotion_period TSTZRANGE NOT NULL,
    discount_percentage NUMERIC(5, 2) NOT NULL,
    promotion_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    EXCLUDE USING gist (product_id WITH =, promotion_period WITH &&),
    CONSTRAINT chk_discount_range CHECK (discount_percentage > 0 AND discount_percentage <= 100)
);

CREATE TABLE outbox_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(80) NOT NULL,
    aggregate_id VARCHAR(80) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    processed_at TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_geo_locations_updated_at BEFORE UPDATE ON geo_locations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_sellers_updated_at BEFORE UPDATE ON sellers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status_purchase ON orders(order_status, order_purchase_timestamp);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_order_items_seller ON order_items(seller_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_specifications_gin ON products USING GIN(product_specifications);
CREATE INDEX idx_products_search_tokens_gin ON products USING GIN(search_tokens);
CREATE INDEX idx_categories_name_trgm ON categories USING GIN(name_en gin_trgm_ops);
CREATE INDEX idx_geolocation_point ON geo_locations USING GIST(geo_point);
CREATE INDEX idx_outbox_unprocessed ON outbox_events(created_at) WHERE processed_at IS NULL;
