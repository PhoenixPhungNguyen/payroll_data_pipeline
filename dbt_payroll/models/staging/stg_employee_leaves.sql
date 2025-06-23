WITH source AS (
    SELECT *
    FROM {{ source('landing', 'employee_leave') }}
),
employee_leaves_transformed AS (
    SELECT
        leave_id,
        employee_id,
        leave_type,
        leave_start_date,
        leave_end_date,
        leave_hours
    FROM source
)
SELECT *
FROM employee_leaves_transformed