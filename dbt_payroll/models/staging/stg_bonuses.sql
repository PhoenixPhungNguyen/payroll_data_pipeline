WITH source AS (
    SELECT *
    FROM {{ source('landing', 'bonus') }}
),
bonuses_transformed AS (
    SELECT
        bonus_id,
        employee_id,
        bonus_type,
        bonus_amount,
        bonus_date
    FROM source
)
SELECT *
FROM bonuses_transformed