-- 1. First, let's see the current data distribution
SELECT year_value, country_name, COUNT(*) as record_count
FROM tb_dw.tb_fact f
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
JOIN tb_dw.country_dim c ON f.country_id = c.surrogate_key
WHERE c.country_code IN ('CD', 'SZ')
GROUP BY year_value, country_name
ORDER BY year_value;

-- 2. Create a more accurate mapping table that considers dates
CREATE TEMPORARY TABLE temp_country_mapping AS
WITH fact_dates AS (
    SELECT f.country_id as old_id,
           y.year_value
    FROM tb_dw.tb_fact f
    JOIN tb_dw.year_dim y ON f.year_id = y.year_id
)
SELECT DISTINCT
    fd.old_id,
    cd.surrogate_key as new_id,
    fd.year_value
FROM fact_dates fd
CROSS JOIN tb_dw.country_dim cd
WHERE 
    -- For CD (Zaire/DR Congo)
    (cd.country_code = 'CD' AND 
     ((fd.year_value < 1997 AND cd.country_name = 'Zaire') OR
      (fd.year_value >= 1997 AND cd.country_name = 'Democratic Republic of the Congo')))
    OR
    -- For SZ (Swaziland/Eswatini)
    (cd.country_code = 'SZ' AND
     ((fd.year_value < 2009 AND cd.country_name = 'Swaziland') OR
      (fd.year_value >= 2009 AND cd.country_name = 'Eswatini')));

-- 3. Update fact table with correct historical references
UPDATE tb_dw.tb_fact f
SET country_id = m.new_id
FROM temp_country_mapping m
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE f.country_id = m.old_id
AND y.year_value = m.year_value;

-- 4. Verify the changes with multiple queries

-- 4.1 Check distribution by country and time period
SELECT 
    cd.country_name,
    cd.country_code,
    cd.effective_start_date,
    cd.effective_end_date,
    cd.is_current,
    COUNT(f.*) as fact_count,
    MIN(y.year_value) as min_year,
    MAX(y.year_value) as max_year
FROM tb_dw.country_dim cd
LEFT JOIN tb_dw.tb_fact f ON cd.surrogate_key = f.country_id
LEFT JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code IN ('CD', 'SZ')
GROUP BY 
    cd.country_name,
    cd.country_code,
    cd.effective_start_date,
    cd.effective_end_date,
    cd.is_current
ORDER BY cd.country_code, cd.effective_start_date;

-- 4.2 Verify no orphaned records
SELECT COUNT(*) as orphaned_records
FROM tb_dw.tb_fact f
WHERE NOT EXISTS (
    SELECT 1 FROM tb_dw.country_dim cd 
    WHERE cd.surrogate_key = f.country_id
);

-- 4.3 Verify temporal consistency
SELECT 
    cd.country_name,
    y.year_value,
    COUNT(*) as record_count
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code IN ('CD', 'SZ')
GROUP BY cd.country_name, y.year_value
HAVING (
    (cd.country_name = 'Zaire' AND y.year_value >= 1997) OR
    (cd.country_name = 'Democratic Republic of the Congo' AND y.year_value < 1997) OR
    (cd.country_name = 'Swaziland' AND y.year_value >= 2009) OR
    (cd.country_name = 'Eswatini' AND y.year_value < 2009)
)
ORDER BY cd.country_name, y.year_value;