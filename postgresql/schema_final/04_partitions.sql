-- 04_partitions.sql
-- Particionamiento declarativo por rango temporal para orders_part.

CREATE TABLE IF NOT EXISTS orders_part_2016 PARTITION OF orders_part
FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE IF NOT EXISTS orders_part_2017 PARTITION OF orders_part
FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE IF NOT EXISTS orders_part_2018 PARTITION OF orders_part
FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE IF NOT EXISTS orders_part_default PARTITION OF orders_part DEFAULT;
