CREATE TABLE orders ( 
  order_id                      VARCHAR(50) PRIMARY KEY, 
  customer_id                   VARCHAR(50) NOT NULL, 
  order_status                  VARCHAR(20) NOT NULL, 
  order_purchase_timestamp      TIMESTAMP   NOT NULL, 
  order_approved_at             TIMESTAMP, 
  order_delivered_carrier_date  TIMESTAMP, 
  order_delivered_customer_date TIMESTAMP, 
  order_estimated_delivery_date TIMESTAMP   NOT NULL, 
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) 
    REFERENCES customers(customer_id), 
  CONSTRAINT chk_order_status CHECK (order_status IN ( 
    'delivered','shipped','canceled','unavailable', 
    'invoiced','processing','created','approved')) 
);