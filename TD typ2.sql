-- Comprehensive verification of historical changes
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
WHERE country_name IN ('Zaire', 'Democratic Republic of the Congo', 'Swaziland', 'Eswatini')
ORDER BY country_code, effective_start_date;

-- Check Zaire to DR Congo transition
SELECT 
    'Zaire to DR Congo' as transition,
    COUNT(*) as record_count,
    COUNT(CASE WHEN effective_end_date = '1997-05-16' THEN 1 END) as old_record,
    COUNT(CASE WHEN effective_start_date = '1997-05-17' THEN 1 END) as new_record
FROM tb_dw.country_dim
WHERE country_name IN ('Zaire', 'Democratic Republic of the Congo');

-- Check Swaziland to Eswatini transition
SELECT 
    'Swaziland to Eswatini' as transition,
    COUNT(*) as record_count,
    COUNT(CASE WHEN effective_end_date = '2008-12-31' THEN 1 END) as old_record,
    COUNT(CASE WHEN effective_start_date = '2009-01-01' THEN 1 END) as new_record
FROM tb_dw.country_dim
WHERE country_name IN ('Swaziland', 'Eswatini');

-- Verify current status is correct
SELECT 
    country_name,
    is_current,
    effective_start_date,
    effective_end_date
FROM tb_dw.country_dim
WHERE country_name IN ('Democratic Republic of the Congo', 'Eswatini')
AND is_current = true;

-- Check for any overlapping dates (should return no rows if correct)
SELECT 
    a.country_code,
    a.country_name as name1,
    b.country_name as name2,
    a.effective_start_date,
    a.effective_end_date,
    b.effective_start_date,
    b.effective_end_date
FROM tb_dw.country_dim a
JOIN tb_dw.country_dim b ON a.country_code = b.country_code
    AND a.surrogate_key < b.surrogate_key
    AND a.effective_start_date <= b.effective_end_date
    AND a.effective_end_date >= b.effective_start_date
WHERE a.country_code IN ('CD', 'SZ');