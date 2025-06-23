WITH source AS (
    SELECT *
    FROM {{ source('landing', 'roster') }}
),
roster_transformed AS (
    SELECT
        roster_id,
        employee_id,
        shift,
        hours,
        work_date,
        services,
        location,
        pay_period_id
    FROM source
    ORDER BY work_date, shift
)
SELECT *
FROM roster_transformed