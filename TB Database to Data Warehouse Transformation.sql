DROP TABLE IF EXISTS tb_dw.tb_fact;
DROP TABLE IF EXISTS tb_dw.gender_dim;
DROP TABLE IF EXISTS tb_dw.year_dim;
DROP TABLE IF EXISTS tb_dw.country_dim;


DROP SEQUENCE IF EXISTS tb_dw.country_dim_country_id_seq;
DROP SEQUENCE IF EXISTS tb_dw.gender_dim_gender_id_seq;

DROP SCHEMA IF EXISTS tb_dw CASCADE;

-- Create new schema
CREATE SCHEMA tb_dw;

-- Verify schema creation
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name = 'tb_dw';

-- Create Country Dimension
CREATE TABLE tb_dw.country_dim (
    country_id serial PRIMARY KEY,
    country_name varchar(100)
);

-- Verify country_dim creation and structure
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'tb_dw' 
AND table_name = 'country_dim'
ORDER BY ordinal_position;

-- Load Country Dimension
INSERT INTO tb_dw.country_dim (country_name)
(SELECT DISTINCT country FROM tb ORDER BY country);

-- Verify country data
SELECT * FROM tb_dw.country_dim ORDER BY country_id;

-- Create Gender Dimension
CREATE TABLE tb_dw.gender_dim (
    gender_id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gender_code char(1),
    gender_desc varchar(10)
);

-- Verify gender_dim creation and structure
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'tb_dw' 
AND table_name = 'gender_dim'
ORDER BY ordinal_position;

-- Load Gender Dimension
INSERT INTO tb_dw.gender_dim (gender_code, gender_desc)
(SELECT DISTINCT upper(substr(sex,1,1)), initcap(sex)
 FROM tb ORDER BY initcap(sex));

-- Add Other gender option
INSERT INTO tb_dw.gender_dim (gender_code, gender_desc)
VALUES ('O', 'Other');

-- Verify gender data
SELECT * FROM tb_dw.gender_dim ORDER BY gender_id;

-- Create Year Dimension
CREATE TABLE tb_dw.year_dim (
    year_id serial PRIMARY KEY,
    year_value int
);

-- Verify year_dim creation and structure
SELECT table_name, column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'tb_dw' 
AND table_name = 'year_dim'
ORDER BY ordinal_position;

-- Load Year Dimension
INSERT INTO tb_dw.year_dim (year_value)
(SELECT DISTINCT year FROM tb ORDER BY year);

-- Verify year data
SELECT * FROM tb_dw.year_dim ORDER BY year_id;

-- Create Fact Table
CREATE TABLE tb_dw.tb_fact (
    country_id int REFERENCES tb_dw.country_dim (country_id),
    year_id int REFERENCES tb_dw.year_dim (year_id),
    gender_id int REFERENCES tb_dw.gender_dim (gender_id),
    child_disease_amt int,
    adult_disease_amt int,
    elderly_disease_amt int,
    PRIMARY KEY (country_id, year_id, gender_id)
);

-- Verify fact table creation and structure
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'tb_dw' 
AND table_name = 'tb_fact'
ORDER BY ordinal_position;

-- Load Fact Table
INSERT INTO tb_dw.tb_fact
(SELECT c.country_id, y.year_id, g.gender_id, t.child, t.adult, t.elderly
 FROM tb t, tb_dw.country_dim c, tb_dw.year_dim y, tb_dw.gender_dim g
 WHERE t.country = c.country_name
 AND t.year = y.year_value
 AND t.sex = lower(g.gender_desc));

-- Verify fact data - basic row count
SELECT COUNT(*) as total_rows FROM tb_dw.tb_fact;
Select count(*) from tb

-- Verify fact data - sample with dimension lookups
SELECT 
    c.country_name,
    y.year_value,
    g.gender_desc,
    f.child_disease_amt,
    f.adult_disease_amt,
    f.elderly_disease_amt
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim c ON f.country_id = c.country_id
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
JOIN tb_dw.gender_dim g ON f.gender_id = g.gender_id
LIMIT 10;

-- Verify referential integrity
SELECT 
    (SELECT COUNT(*) FROM tb_dw.tb_fact f 
     LEFT JOIN tb_dw.country_dim c ON f.country_id = c.country_id 
     WHERE c.country_id IS NULL) as orphaned_country_refs,
    (SELECT COUNT(*) FROM tb_dw.tb_fact f 
     LEFT JOIN tb_dw.year_dim y ON f.year_id = y.year_id 
     WHERE y.year_id IS NULL) as orphaned_year_refs,
    (SELECT COUNT(*) FROM tb_dw.tb_fact f 
     LEFT JOIN tb_dw.gender_dim g ON f.gender_id = g.gender_id 
     WHERE g.gender_id IS NULL) as orphaned_gender_refs;


--Check Null Values
SELECT * FROM tb WHERE child IS NULL;

--Retrieve Data for Central American Countries after 2000 with Gender-Based Condition:
SELECT c.country_name, y.year_value, g.gender_code, f.adult_disease_amt
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim c ON f.country_id = c.country_id
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
JOIN tb_dw.gender_dim g ON f.gender_id = g.gender_id
WHERE c.country_id IN (40, 37, 64)
  AND y.year_value > 2000
  AND g.gender_code = 'F'
  AND EXISTS (
      SELECT 1
      FROM tb_dw.tb_fact m
      WHERE m.year_id = f.year_id
        AND m.country_id = f.country_id
        AND m.gender_id <> f.gender_id
        AND f.adult_disease_amt > m.adult_disease_amt
  )
ORDER BY c.country_name, y.year_value, g.gender_code;

--Check Data for Only Two Years and Countries:

SELECT c.country_name, y.year_value, g.gender_code, f.adult_disease_amt
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim c ON f.country_id = c.country_id
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
JOIN tb_dw.gender_dim g ON f.gender_id = g.gender_id
WHERE f.country_id IN (37, 64)
  AND y.year_value > 2000
ORDER BY c.country_name, y.year_value, g.gender_code;

