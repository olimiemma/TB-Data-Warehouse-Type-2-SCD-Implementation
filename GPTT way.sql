-- Alter country_dim to support Type 2 SCD
ALTER TABLE tb_dw.country_dim
ADD COLUMN country_code CHAR(2), -- Natural Key (e.g., AF for Afghanistan)
ADD COLUMN begin_effective_date DATE,
ADD COLUMN end_effective_date DATE,
ADD COLUMN change_reason_text VARCHAR(255),
ADD COLUMN current_flag BOOLEAN DEFAULT TRUE,
ADD COLUMN precise_time_stamp TIMESTAMP,
ADD COLUMN time_stamp_of_next_change TIMESTAMP;

-- Update country_code column with available alpha-2 codes
UPDATE tb_dw.country_dim
SET country_code = CASE country_name
    WHEN 'Democratic Republic of the Congo' THEN 'CD'
    WHEN 'Eswatini' THEN 'SZ'
   
    ELSE 'NA'
END;

-- Set initial values for administrative fields
UPDATE tb_dw.country_dim
SET begin_effective_date = '1900-01-01',
    end_effective_date = '9999-12-31', -- Fictitious future date for current record
    change_reason_text = 'Initial Load',
    precise_time_stamp = NOW(),
    time_stamp_of_next_change = NULL,
    current_flag = TRUE;

-- Verify the new structure
SELECT * FROM tb_dw.country_dim;


-- Update for Zaire to Democratic Republic of the Congo (Change effective from 1997)
UPDATE tb_dw.country_dim
SET end_effective_date = '1997-01-01', current_flag = FALSE, time_stamp_of_next_change = NOW()
WHERE country_code = 'ZR' AND current_flag = TRUE;

INSERT INTO tb_dw.country_dim (country_name, country_code, begin_effective_date, end_effective_date, change_reason_text, current_flag, precise_time_stamp)
VALUES ('Democratic Republic of the Congo', 'CD', '1997-01-01', '9999-12-31', 'Country renamed from Zaire', TRUE, NOW());

-- Update for Swaziland to Eswatini (Change effective from 2008)
UPDATE tb_dw.country_dim
SET end_effective_date = '2008-01-01', current_flag = FALSE, time_stamp_of_next_change = NOW()
WHERE country_code = 'SZ' AND current_flag = TRUE;

INSERT INTO tb_dw.country_dim (country_name, country_code, begin_effective_date, end_effective_date, change_reason_text, current_flag, precise_time_stamp)
VALUES ('Eswatini', 'SZ', '2008-01-01', '9999-12-31', 'Country renamed from Swaziland', TRUE, NOW());

-- Verify changes
SELECT * FROM tb_dw.country_dim
ORDER BY country_code, begin_effective_date;


-- Drop old foreign key constraint
ALTER TABLE tb_dw.tb_fact DROP CONSTRAINT tb_fact_country_id_fkey;

-- Re-add foreign key constraint to account for updated surrogate keys
ALTER TABLE tb_dw.tb_fact
ADD CONSTRAINT tb_fact_country_id_fkey
FOREIGN KEY (country_id)
REFERENCES tb_dw.country_dim (country_id);

-- Align tb_fact with correct surrogate keys from the modified country_dim
UPDATE tb_dw.tb_fact f
SET country_id = (
    SELECT country_id 
    FROM tb_dw.country_dim d
    WHERE d.country_code = 'CD' -- Natural Key
      AND d.begin_effective_date <= TO_DATE((SELECT year_value FROM tb_dw.year_dim WHERE year_id = f.year_id)::TEXT, 'YYYY')
      AND (d.end_effective_date > TO_DATE((SELECT year_value FROM tb_dw.year_dim WHERE year_id = f.year_id)::TEXT, 'YYYY') OR d.end_effective_date = '9999-12-31')
      AND d.current_flag = TRUE
)
WHERE f.country_id = (
    SELECT country_id 
    FROM tb_dw.country_dim 
    WHERE country_code = 'ZR'
);


-- Verify fact data after updating foreign key references
SELECT * FROM tb_dw.tb_fact
ORDER BY country_id, year_id;

-- Verify varying dimension data for Democratic Republic of the Congo
SELECT * FROM tb_dw.country_dim
WHERE country_code = 'CD';

-- Query fact table data with current country reference
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
WHERE c.country_code = 'CD'
ORDER BY y.year_value;

