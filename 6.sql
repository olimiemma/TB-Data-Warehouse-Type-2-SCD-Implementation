-- First, check DR Congo records before update
SELECT 
    cd.country_name,
    cd.country_code,
    y.year_value,
    COUNT(*) as record_count
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code = 'CD'
GROUP BY cd.country_name, cd.country_code, y.year_value
ORDER BY y.year_value;

-- Update Democratic Republic of the Congo records based on year
UPDATE tb_dw.tb_fact f
SET country_id = (
    SELECT CASE 
        WHEN y.year_value < 1997 THEN 
            (SELECT surrogate_key FROM tb_dw.country_dim WHERE country_name = 'Zaire')
        ELSE 
            (SELECT surrogate_key FROM tb_dw.country_dim WHERE country_name = 'Democratic Republic of the Congo')
    END
)
FROM tb_dw.year_dim y
WHERE f.year_id = y.year_id
AND f.country_id IN (
    SELECT surrogate_key 
    FROM tb_dw.country_dim 
    WHERE country_name = 'Democratic Republic of the Congo'
);

-- Verify the changes - this should show records for both Zaire and DR Congo
SELECT 
    cd.country_name,
    cd.country_code,
    y.year_value,
    COUNT(*) as record_count
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code = 'CD'
GROUP BY cd.country_name, cd.country_code, y.year_value
ORDER BY y.year_value;