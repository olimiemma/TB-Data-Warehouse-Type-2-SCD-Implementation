-- This is where the magic happens for historical versioning
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
    -- For Swaziland/Eswatini
    (cd.country_code = 'SZ' AND
     ((fd.year_value < 2009 AND cd.country_name = 'Swaziland') OR
      (fd.year_value >= 2009 AND cd.country_name = 'Eswatini')));

-- Then this update applies the mapping
UPDATE tb_dw.tb_fact f
SET country_id = m.new_id
FROM temp_country_mapping m
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE f.country_id = m.old_id
AND y.year_value = m.year_value;