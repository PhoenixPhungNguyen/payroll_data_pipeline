WITH source AS (
    SELECT *
    FROM {{ source('landing', 'minimum_pay_rates') }}
),
minimum_pay_rates_transformed AS (
    SELECT
        pay_rate_id,
        effect_from,
        effect_to,
        hourly_permanent_rate,
        hourly_casual_rate
    FROM source
    ORDER BY pay_rate_id
)
SELECT *
FROM minimum_pay_rates_transformed