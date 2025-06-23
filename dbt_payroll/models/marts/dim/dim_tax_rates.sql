{{
    config(
        materialized='incremental',
        unique_key='tax_rate_pk',
    )
}}
WITH tax_rates AS (
    SELECT
        tax_rate_id AS tax_rate_pk,
        taxable_income,
        tax_on_this_income,
        year,
        note,
        start_range,
        end_range,
        date_start,
        date_end,
        fixed_tax,
        cumulative_tax
    FROM {{ ref('stg_tax_rates') }}
)
SELECT *
FROM tax_rates