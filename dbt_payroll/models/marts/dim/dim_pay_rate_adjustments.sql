{{
    config(
        materialized='incremental',
        unique_key='pay_rate_pk',
    )
}}
WITH pay_rate_adjustments AS (
    SELECT
        pay_rate_id AS pay_rate_pk,
        rate_type,
        description,
        rate_calculation,
        CASE
            WHEN pay_rate_id = 'CLR' THEN 1.25
            WHEN pay_rate_id = 'NSP' THEN 1.25
            WHEN pay_rate_id = 'ORA' THEN 2.0
            WHEN pay_rate_id = 'ORF' THEN 1.5
            WHEN pay_rate_id = 'ORS' THEN 2.5
            WHEN pay_rate_id = 'PRS' THEN 2.0
            ELSE NULL
        END AS rate_multiplier
    FROM {{ ref('stg_pay_rate_adjustments') }}
)
SELECT *
FROM pay_rate_adjustments