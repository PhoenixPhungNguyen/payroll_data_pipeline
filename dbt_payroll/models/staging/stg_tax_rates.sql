WITH source AS (
    SELECT *
    FROM {{ source('landing', 'tax_rates') }}
),
tax_rates_transformed AS (
    SELECT
        CONCAT('TR', REGEXP_REPLACE(year, '[^0-9]', ''), '_', REGEXP_REPLACE(start_range, '[^0-9]', ''), '_', REGEXP_REPLACE(end_range, '[^0-9]', '')) as tax_rate_id,
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
    FROM source
    ORDER BY date_start, start_range
)
SELECT *
FROM tax_rates_transformed