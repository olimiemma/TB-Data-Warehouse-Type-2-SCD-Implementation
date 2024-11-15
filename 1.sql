- First fix the duplicate DR Congo records
UPDATE tb_dw.country_dim
SET effective_end_date = '1997-05-16',
    is_current = false
WHERE country_name = 'Democratic Republic of the Congo' 
AND effective_start_date = '1900-01-01';

-- Insert the missing Zaire record
INSERT INTO tb_dw.country_dim 
(country_name, country_code, effective_start_date, effective_end_date, is_current)
VALUES 
('Zaire', 'CD', '1900-01-01', '1997-05-16', false);


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

DELETE FROM tb_dw.country_dim 
WHERE country_name = 'Democratic Republic of the Congo';


-- Then DR Congo
INSERT INTO tb_dw.country_dim 
(country_name, country_code, effective_start_date, effective_end_date, is_current)
VALUES 
('Democratic Republic of the Congo', 'CD', '1997-05-17', '9999-12-31', true);
