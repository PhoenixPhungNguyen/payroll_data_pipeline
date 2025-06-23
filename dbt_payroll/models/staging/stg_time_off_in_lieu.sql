WITH source AS (
    SELECT *
    FROM {{ source('landing', 'time_off_in_lieu') }}
),
time_off_in_lieu_transformed AS (
    SELECT
        toil_id,
        employee_id,
        overtime_date,
        toil_hours_accrued,
        toil_usage_date
    FROM source
)
SELECT *
FROM time_off_in_lieu_transformed