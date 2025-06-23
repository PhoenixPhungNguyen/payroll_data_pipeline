WITH source AS (
    SELECT *
    FROM {{ source('landing', 'combined_holidays') }}
),
holidays_transformed AS (
    SELECT
        holiday_date,
        holiday_name,
        information,
        more_information AS reference_url,
        jurisdiction,
        day_of_week
    FROM source
    ORDER BY holiday_date
)
SELECT *
FROM holidays_transformed