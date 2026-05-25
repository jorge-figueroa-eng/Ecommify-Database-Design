CREATE INDEX idx_orders_customer ON orders(customer_id); 
CREATE INDEX idx_items_product   ON order_items(product_id); 
CREATE INDEX idx_items_seller    ON order_items(seller_id); 


CREATE INDEX idx_orders_status   ON orders(order_status); 
CREATE INDEX idx_payments_type   ON order_payments(payment_type); 


CREATE INDEX idx_orders_purchase ON orders(order_purchase_timestamp);