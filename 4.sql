-- 1. First check if CD exists in our country_dim
SELECT *
FROM tb_dw.country_dim
WHERE country_code = 'CD';

SELECT DISTINCT country
FROM tb
WHERE country LIKE '%Congo%' 
   OR country = 'Zaire';


SELECT 
    country_id,
    country_name,
    country_code,
    effective_start_date,
    effective_end_date,
    is_current
FROM tb_dw.country_dim
WHERE country_code = 'CD'
    OR country_name LIKE '%Congo%'
    OR country_name = 'Zaire';

SELECT DISTINCT t.country, y.year_value
FROM tb t
JOIN tb_dw.year_dim y ON t.year = y.year_value
WHERE t.country LIKE '%Congo%'
ORDER BY t.country, y.year_value;