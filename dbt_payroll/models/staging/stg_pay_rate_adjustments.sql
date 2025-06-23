WITH source AS (
    SELECT *
    FROM {{ source('landing', 'pay_rate_adjustments') }}
),
pay_rate_adjustments_transformed AS (
    SELECT
        REGEXP_REPLACE(rate_type, '[^A-Z]', '') as pay_rate_id,
        rate_type,
        description,
        rate_calculation
    FROM source
    ORDER BY pay_rate_id
)
SELECT *
FROM pay_rate_adjustments_transformed