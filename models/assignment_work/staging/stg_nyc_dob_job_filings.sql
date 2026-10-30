-- Clean and standardize NYC DOB Job Filings data
-- One row per job filing

WITH source AS (
   SELECT * FROM {{ source('nyc_service_job_apps_hw', 'source_service_job_apps_homework') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           job_filing_number,
           filing_date,
           signoff_date,
           approved_date,
           applicant_license,
           applicant_first_name,
           applicant_last_name,
           owner_s_business_name,
           initial_cost,
           job_description,
           building_type,
           bin,
           borough,
           latitude,
           longitude,
           zip,
           incident_address,
           street_name,
           applicant_business_name,
           filing_status
       ),

       -- Identifiers
       CAST(job_filing_number AS STRING) AS job_filing_id,

       -- Date/Time
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(signoff_date AS TIMESTAMP) AS signoff_date,
       CAST(approved_date AS TIMESTAMP) AS approved_date,

       -- Job Filing details
       CAST(applicant_license AS STRING) AS applicant_license,
       CAST(applicant_first_name AS STRING) AS applicant_first_name,
       CAST(applicant_last_name AS STRING) AS applicant_last_name,
       CAST(applicant_business_name AS STRING) AS applicant_business_name,
       CAST(owner_s_business_name AS STRING) AS owner_s_business_name,
       CAST(initial_cost AS DECIMAL) AS initial_cost,
       CAST(job_description AS STRING) AS job_description,
       CAST(building_type AS STRING) AS building_type,
       CAST(bin AS STRING) as bin,
       UPPER(TRIM(CAST(filing_status AS STRING))) AS filing_status,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       CAST(incident_address AS STRING) AS incident_address,
       CAST(street_name AS STRING) AS street_name,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- Clearer column name as well for this one
       --CAST(open_data_channel_type AS STRING) AS method_of_submission,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE job_filing_number IS NOT NULL
   AND filing_date IS NOT NULL
   AND CAST(filing_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_filings
