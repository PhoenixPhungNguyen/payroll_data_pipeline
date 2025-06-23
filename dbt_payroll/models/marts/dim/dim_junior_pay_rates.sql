{{
    config(
        materialized='incremental',
        unique_key='pay_rate_pk',
    )
}}
WITH junior_pay_rates AS (
    SELECT
        pay_rate_id AS pay_rate_pk,
        age,
        percent_of_adult_pay_rate/100 AS adult_pay_rate_multiplier
    FROM {{ ref('stg_junior_pay_rates') }}
)
SELECT *
FROM junior_pay_rates