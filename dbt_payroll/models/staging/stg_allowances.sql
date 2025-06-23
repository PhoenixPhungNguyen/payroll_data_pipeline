WITH source AS (
    SELECT *
    FROM {{ source('landing', 'allowance') }}
),
allowances_transformed AS (
    SELECT
        allowance_id,
        employee_id,
        allowance_type,
        allowance_amount,
        allowance_start_date,
        allowance_end_date
    FROM source
)
SELECT *
FROM allowances_transformed