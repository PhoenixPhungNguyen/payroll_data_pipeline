{{
    config(
        materialized='incremental',
        unique_key='pay_rate_pk',
    )
}}
WITH minimum_pay_rates AS (
    SELECT
        pay_rate_id AS pay_rate_pk,
        effect_from,
        effect_to,
        hourly_permanent_rate,
        hourly_casual_rate
    FROM {{ ref('stg_minimum_pay_rates') }}
)
SELECT *
FROM minimum_pay_rates