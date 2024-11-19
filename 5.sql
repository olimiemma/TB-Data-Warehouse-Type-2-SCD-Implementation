-- Check what we have in the original tb table for these specific countries
SELECT DISTINCT country 
FROM tb 
WHERE country IN ('Zaire', 'Democratic Republic of the Congo', 'Swaziland');

-- Check what's in our current country_dim
SELECT *
FROM tb_dw.country_dim
WHERE country_name IN ('Zaire', 'Democratic Republic of the Congo', 'Swaziland', 'Eswatini')
OR country_code IN ('CD', 'SZ')
ORDER BY country_code, effective_start_date;

-- Check fact table distribution
SELECT 
    cd.country_name,
    cd.country_code,
    y.year_value,
    COUNT(*) as record_count
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code IN ('CD', 'SZ')
GROUP BY cd.country_name, cd.country_code, y.year_value
ORDER BY cd.country_code, y.year_value;


-- Update fact table mappings for our two specific cases
WITH fact_dates AS (
    SELECT f.country_id as old_id,
           y.year_value,
           t.country as original_name
    FROM tb_dw.tb_fact f
    JOIN tb_dw.year_dim y ON f.year_id = y.year_id
    JOIN tb t ON t.year = y.year_value
    WHERE t.country IN ('Zaire', 'Democratic Republic of the Congo', 'Swaziland')
)
UPDATE tb_dw.tb_fact f
SET country_id = 
    CASE 
        --WHEN fd.original_name = 'Swaziland' AND fd.year_value >= 2009 THEN 
           -- (SELECT surrogate_key FROM tb_dw.country_dim WHERE country_name = 'Eswatini')
        WHEN fd.original_name = 'Zaire' AND fd.year_value >= 1997 THEN 
            (SELECT surrogate_key FROM tb_dw.country_dim WHERE country_name = 'Democratic Republic of the Congo')
        ELSE f.country_id
    END
FROM fact_dates fd
WHERE f.country_id = fd.old_id;

-- Verify the changes
SELECT 
    cd.country_name,
    cd.country_code,
    y.year_value,
    COUNT(*) as record_count
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code IN ('CD', 'SZ')
GROUP BY cd.country_name, cd.country_code, y.year_value
ORDER BY cd.country_code, y.year_value;