CREATE TABLE order_payments ( 
  order_id             VARCHAR(50)   NOT NULL, 
  payment_sequential   INTEGER       NOT NULL, 
  payment_type         VARCHAR(20)   NOT NULL, 
  payment_installments INTEGER       NOT NULL, 
  payment_value        NUMERIC(10,2) NOT NULL, 
  CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential), 
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) 
    REFERENCES orders(order_id), 
  CONSTRAINT chk_payment_type CHECK (payment_type IN ( 
    'credit_card','boleto','voucher','debit_card','not_defined')), 
  CONSTRAINT chk_payment_value CHECK (payment_value >= 0) 
);