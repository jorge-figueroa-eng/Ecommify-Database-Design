-- 03_tables.sql
-- Modelo relacional final para Supabase/PostgreSQL.

CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  customer_unique_id TEXT NOT NULL,
  customer_zip_code_prefix INT NOT NULL,
  customer_city TEXT NOT NULL,
  customer_state br_state NOT NULL,
  address_snapshot address_br,
  customer_tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE geolocations (
  geolocation_id BIGSERIAL PRIMARY KEY,
  geolocation_zip_code_prefix INT NOT NULL,
  geolocation_lat DOUBLE PRECISION NOT NULL CHECK (geolocation_lat BETWEEN -90 AND 90),
  geolocation_lng DOUBLE PRECISION NOT NULL CHECK (geolocation_lng BETWEEN -180 AND 180),
  geolocation_city TEXT NOT NULL,
  geolocation_state br_state NOT NULL,
  geom GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
    ST_SetSRID(ST_MakePoint(geolocation_lng, geolocation_lat), 4326)::geography
  ) STORED,
  raw_payload JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE sellers (
  seller_id TEXT PRIMARY KEY,
  seller_zip_code_prefix INT NOT NULL,
  seller_city TEXT NOT NULL,
  seller_state br_state NOT NULL,
  seller_tags TEXT[] DEFAULT '{}',
  capabilities JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE product_categories (
  product_category_name TEXT PRIMARY KEY,
  product_category_name_english TEXT,
  search_aliases TEXT[] DEFAULT '{}'
);

CREATE TABLE products (
  product_id TEXT PRIMARY KEY,
  product_category_name TEXT REFERENCES product_categories(product_category_name),
  product_name_lenght INT,
  product_description_lenght INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT,
  product_volume_cm3 INT GENERATED ALWAYS AS (
    COALESCE(product_length_cm,0) * COALESCE(product_height_cm,0) * COALESCE(product_width_cm,0)
  ) STORED,
  specs JSONB DEFAULT '{}'::jsonb,
  search_tokens TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  CHECK (product_weight_g IS NULL OR product_weight_g >= 0)
);

CREATE TABLE orders (
  order_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customers(customer_id),
  order_status order_status_enum NOT NULL,
  order_purchase_timestamp TIMESTAMPTZ NOT NULL,
  order_approved_at TIMESTAMPTZ,
  order_delivered_carrier_date TIMESTAMPTZ,
  order_delivered_customer_date TIMESTAMPTZ,
  order_estimated_delivery_date TIMESTAMPTZ,
  raw_payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  CHECK (order_estimated_delivery_date IS NULL OR order_estimated_delivery_date >= order_purchase_timestamp)
);

-- Tabla particionada para evidenciar optimizacion declarativa por rango temporal.
-- Se alimenta desde orders despues de la carga.
CREATE TABLE orders_part (
  order_id TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  order_status order_status_enum NOT NULL,
  order_purchase_timestamp TIMESTAMPTZ NOT NULL,
  order_approved_at TIMESTAMPTZ,
  order_delivered_carrier_date TIMESTAMPTZ,
  order_delivered_customer_date TIMESTAMPTZ,
  order_estimated_delivery_date TIMESTAMPTZ,
  raw_payload JSONB DEFAULT '{}'::jsonb,
  PRIMARY KEY (order_id, order_purchase_timestamp)
) PARTITION BY RANGE (order_purchase_timestamp);

CREATE TABLE order_items (
  order_id TEXT NOT NULL REFERENCES orders(order_id),
  order_item_id INT NOT NULL,
  product_id TEXT REFERENCES products(product_id),
  seller_id TEXT REFERENCES sellers(seller_id),
  shipping_limit_date TIMESTAMPTZ,
  price NUMERIC(12,2) CHECK (price >= 0),
  freight_value NUMERIC(12,2) CHECK (freight_value >= 0),
  item_metadata JSONB DEFAULT '{}'::jsonb,
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
  payment_id BIGSERIAL PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(order_id),
  payment_sequential INT NOT NULL,
  payment_type payment_type_enum NOT NULL,
  payment_installments INT NOT NULL CHECK (payment_installments >= 0),
  payment_value NUMERIC(12,2) NOT NULL CHECK (payment_value >= 0),
  payment_metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE order_reviews (
  review_pk BIGSERIAL PRIMARY KEY,
  review_id TEXT NOT NULL,
  order_id TEXT NOT NULL REFERENCES orders(order_id),
  review_score INT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date TIMESTAMPTZ,
  review_answer_timestamp TIMESTAMPTZ,
  review_tags TEXT[] DEFAULT '{}',
  review_metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE outbox_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','processing','processed','failed'))
);
