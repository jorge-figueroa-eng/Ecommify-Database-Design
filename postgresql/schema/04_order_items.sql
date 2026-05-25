CREATE TABLE order_items ( 
  order_id            VARCHAR(50)   NOT NULL, 
  order_item_id       INTEGER       NOT NULL, 
  product_id          VARCHAR(50)   NOT NULL, 
  seller_id           VARCHAR(50)   NOT NULL, 
  shipping_limit_date TIMESTAMP     NOT NULL, 
  price               NUMERIC(10,2) NOT NULL, 
  freight_value       NUMERIC(10,2) NOT NULL, 
  CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id), 
  CONSTRAINT fk_items_order  FOREIGN KEY (order_id) 
    REFERENCES orders(order_id), 
  CONSTRAINT fk_items_seller FOREIGN KEY (seller_id) 
    REFERENCES sellers(seller_id), 
  CONSTRAINT chk_price CHECK (price >= 0), 
  CONSTRAINT chk_freight CHECK (freight_value >= 0) 
);