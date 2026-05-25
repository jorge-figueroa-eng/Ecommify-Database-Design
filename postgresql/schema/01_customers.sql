CREATE TABLE customers ( 

  customer_id          VARCHAR(50)  PRIMARY KEY, 

  customer_unique_id   VARCHAR(50)  NOT NULL, 

  customer_zip_code_prefix VARCHAR(10), 

  customer_city        VARCHAR(100) NOT NULL, 

  customer_state       CHAR(2)      NOT NULL, 

  CONSTRAINT chk_customer_state CHECK (LENGTH(customer_state) = 2) 

); 