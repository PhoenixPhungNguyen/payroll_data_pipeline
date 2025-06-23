{{
    config(
        materialized='incremental',
        unique_key='super_guarantee_rate_pk',
    )
}}
WITH super_guarantee_rates AS (
    SELECT
        super_guarantee_rate_id AS super_guarantee_rate_pk,
        start_period,
        end_period,
        super_guarantee_rate_percentage/100 AS super_guarantee_rate_multiplier
    FROM {{ ref('stg_super_guarantee_rates') }}
)
SELECT *
FROM super_guarantee_rates