# TB Data Warehouse Type 2 SCD Implementation

## Overview
This project implements Type 2 Slowly Changing Dimension (SCD) for country names in a Tuberculosis Data Warehouse. It specifically handles historical country name changes:
- Zaire → Democratic Republic of the Congo (1997)
- Swaziland → Eswatini (2008)

## Purpose
The implementation ensures accurate historical reporting by maintaining temporal data integrity, allowing queries to reference the correct country names based on specific time periods.

## Key Features
- Type 2 SCD implementation for country dimension
- Historical tracking of country name changes
- Temporal data integrity in fact table relationships
- Performance optimized indexing
- Data verification queries

## Technical Details

### Database Schema
- Schema Name: tb_dw
- Key Tables:
  - country_dim (Type 2 SCD)
  - year_dim
  - gender_dim
  - tb_fact

### SCD Implementation Details
1. **Country Dimension Changes:**
   - Added surrogate keys
   - Added temporal tracking columns
   - Maintained ISO country codes
   - Preserved historical names

2. **Fact Table Modifications:**
   - Updated foreign key relationships
   - Implemented temporal referencing
   - Maintained data integrity

## Key Concepts
- **Surrogate Keys:** Used instead of natural keys to track multiple versions of the same country
- **Temporal Integrity:** Ensures facts point to historically accurate country names
- **Data Versioning:** Maintains both current and historical country names

## Usage Examples

### Get Current Country Names
```sql
SELECT country_name, country_code 
FROM tb_dw.v_country_dim_current;
```

### Get Historical Data
```sql
SELECT 
    cd.country_name,
    y.year_value,
    f.child_disease_amt,
    f.adult_disease_amt,
    f.elderly_disease_amt
FROM tb_dw.tb_fact f
JOIN tb_dw.country_dim cd ON f.country_id = cd.surrogate_key
JOIN tb_dw.year_dim y ON f.year_id = y.year_id
WHERE cd.country_code IN ('CD', 'SZ')
ORDER BY y.year_value;
```

## Installation/Implementation Steps
1. Run cleanup script
2. Implement SCD changes
3. Update fact table relationships
4. Verify data integrity

## Data Verification
Use provided verification queries to ensure:
- Correct historical transitions
- Proper fact table relationships
- No orphaned records
- Temporal consistency
