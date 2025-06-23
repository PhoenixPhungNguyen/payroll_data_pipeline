WITH source AS (
    SELECT *
    FROM {{ source('landing', 'super_guarantee_rates_formatted') }}
),
super_guarantee_rates_transformed AS (
    SELECT
        CONCAT('SGR', extract(year from start_period)::text) as super_guarantee_rate_id,
        start_period,
        end_period,
        super_guarantee_rate_percentage
    FROM source
    ORDER BY start_period, end_period
)
SELECT *
FROM super_guarantee_rates_transformed