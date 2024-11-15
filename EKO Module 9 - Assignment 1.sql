-- 1. First remove the foreign key constraint from fact table
ALTER TABLE tb_dw.tb_fact
DROP CONSTRAINT tb_fact_country_id_fkey;

-- 2. Now we can alter the country_dim table to add Type 2 SCD fields
ALTER TABLE tb_dw.country_dim 
ADD COLUMN country_code char(2),
ADD COLUMN effective_start_date date,
ADD COLUMN effective_end_date date,
ADD COLUMN is_current boolean,
DROP CONSTRAINT country_dim_pkey CASCADE,
ADD COLUMN surrogate_key serial PRIMARY KEY;

-- 3. Update existing records with initial values
UPDATE tb_dw.country_dim
SET country_code = 'NA',
    effective_start_date = '1900-01-01',
    effective_end_date = '9999-12-31',
    is_current = true;

-- 4. Update specific countries with their  codes
UPDATE tb_dw.country_dim
SET country_code = 'CD'
WHERE country_name = 'Democratic Republic of the Congo';

UPDATE tb_dw.country_dim
SET country_code = 'SZ'
WHERE country_name = 'Swaziland';  


-- Verify changes
SELECT * 
FROM tb_dw.country_dim 
WHERE country_code != 'NA' 
ORDER BY country_code;

-- 5. Handle historical changes
-- 5.1 Zaire to Democratic Republic of the Congo (1997)
UPDATE tb_dw.country_dim
SET effective_end_date = '1997-05-16',
    is_current = false
WHERE country_name = 'Zaire';

INSERT INTO tb_dw.country_dim 
(country_name, country_code, effective_start_date, effective_end_date, is_current)
VALUES 
('Democratic Republic of the Congo', 'CD', '1997-05-17', '9999-12-31', true);

-- 5.2 Swaziland to Eswatini (2008 for this exercise)
UPDATE tb_dw.country_dim
SET effective_end_date = '2008-12-31',
    is_current = false
WHERE country_name = 'Swaziland';

INSERT INTO tb_dw.country_dim 
(country_name, country_code, effective_start_date, effective_end_date, is_current)
VALUES 
('Eswatini', 'SZ', '2009-01-01', '9999-12-31', true);


-- Verify the changes
SELECT 
    country_name,
    country_code,
    effective_start_date,
    effective_end_date,
    is_current,
    CASE 
        WHEN effective_end_date = '9999-12-31' THEN 'Current Name'
        ELSE 'Historical Name'
    END as status
FROM tb_dw.country_dim
WHERE country_code IN ('CD', 'SZ')
ORDER BY country_code, effective_start_date;




-- 6. Create a view to help maintain fact table relationships
CREATE OR REPLACE VIEW tb_dw.v_country_dim_current AS
SELECT surrogate_key as country_id, country_name
FROM tb_dw.country_dim
WHERE is_current = true;

-- 7. Update fact table to use new surrogate keys
-- First, create a temporary mapping table
CREATE TEMPORARY TABLE temp_country_mapping AS
SELECT f.country_id as old_id, 
       c.surrogate_key as new_id
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim c ON c.country_name = 
    (SELECT country_name FROM tb_dw.country_dim 
     WHERE country_id = f.country_id AND 
     CASE 
         WHEN f.country_id = (SELECT country_id FROM tb_dw.country_dim WHERE country_name = 'Swaziland')
         THEN effective_start_date <= '2008-12-31'
         ELSE true
     END);

-- Update the fact table with new surrogate keys
UPDATE tb_dw.tb_fact f
SET country_id = m.new_id
FROM temp_country_mapping m
WHERE f.country_id = m.old_id;

-- 8. Add the foreign key constraint back
ALTER TABLE tb_dw.tb_fact
ADD CONSTRAINT tb_fact_country_id_fkey 
FOREIGN KEY (country_id) REFERENCES tb_dw.country_dim(surrogate_key);

-- 9. Create indexes for performance
CREATE INDEX idx_country_dim_current 
ON tb_dw.country_dim(is_current)
WHERE is_current = true;

CREATE INDEX idx_country_dim_dates 
ON tb_dw.country_dim(effective_start_date, effective_end_date);

-- 10. Verification Queries
-- Check current country names
SELECT country_name, country_code, effective_start_date, effective_end_date, is_current
FROM tb_dw.country_dim
WHERE country_code IN ('CD', 'SZ')
ORDER BY country_name, effective_start_date;

-- Check historical changes
SELECT 
    country_name,
    country_code,
    effective_start_date,
    effective_end_date,
    is_current
FROM tb_dw.country_dim
WHERE country_code IN ('CD', 'SZ')
    OR country_name IN ('Zaire', 'Swaziland')
ORDER BY country_code, effective_start_date;


-- Additional query to verify the changes
SELECT 
    cd.country_name,
    cd.country_code,
    cd.effective_start_date,
    cd.effective_end_date,
    cd.is_current,
    COUNT(f.country_id) as fact_count
FROM tb_dw.country_dim cd
LEFT JOIN tb_dw.tb_fact f ON cd.surrogate_key = f.country_id
WHERE cd.country_code IN ('CD', 'SZ')
GROUP BY 
    cd.country_name,
    cd.country_code,
    cd.effective_start_date,
    cd.effective_end_date,
    cd.is_current
ORDER BY cd.country_code, cd.effective_start_date;
















/*

-- Check fact table relationships
SELECT DISTINCT 
    cd.country_name,
    cd.effective_start_date,
    cd.effective_end_date,
    cd.is_current,
    COUNT(*) OVER (PARTITION BY cd.country_name) as version_count
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
WHERE cd.country_code IN ('CD', 'SZ')
ORDER BY cd.country_name, cd.effective_start_date;
