WITH source AS (
    SELECT *
    FROM {{ source('landing', 'employee_details') }}
),
employees_transformed AS (
    SELECT
        employee_id,
        employee_first_name,
        employee_middle_name,
        employee_last_name,
        employee_gender,
        employee_location,
        date_of_birth,
        hire_date,
        termination_date,
        employee_status
    FROM source
    ORDER BY employee_id
)
SELECT *
FROM employees_transformed