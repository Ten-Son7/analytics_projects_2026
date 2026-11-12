-- CIS 9440 Group 6 - Milestone 4
-- Time dimension shared by 311 requests and parking violations
-- Grain: one row per hour of the day

WITH all_hours AS (

    SELECT hour
    FROM UNNEST(GENERATE_ARRAY(0, 23)) AS hour

),

time_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['hour']) }}
            AS time_key,

        hour,

        CASE
            WHEN hour < 12 THEN 'AM'
            ELSE 'PM'
        END AS am_pm,

        CASE
            WHEN hour BETWEEN 5 AND 11 THEN 'Morning'
            WHEN hour BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN hour BETWEEN 17 AND 20 THEN 'Evening'
            ELSE 'Night'
        END AS time_of_day

    FROM all_hours

),

-- Placeholder row for missing time values
null_placeholder AS (

    SELECT
        '-1' AS time_key,
        CAST(NULL AS INT64) AS hour,
        CAST(NULL AS STRING) AS am_pm,
        CAST(NULL AS STRING) AS time_of_day

)

SELECT * FROM time_dimension

UNION ALL

SELECT * FROM null_placeholder