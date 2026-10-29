-- Quick test to verify source connection works
 SELECT
     unique_key,
     created_date,
     complaint_type,
     borough
 FROM {{ source('311_service_request_hw', 'source_service_requests_homework') }}
 LIMIT 10
