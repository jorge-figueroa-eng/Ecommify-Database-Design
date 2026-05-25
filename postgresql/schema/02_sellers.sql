CREATE TABLE sellers ( 
  seller_id            VARCHAR(50)  PRIMARY KEY, 
  seller_zip_code_prefix VARCHAR(10), 
  seller_city          VARCHAR(100) NOT NULL, 
  seller_state         CHAR(2)      NOT NULL 
);