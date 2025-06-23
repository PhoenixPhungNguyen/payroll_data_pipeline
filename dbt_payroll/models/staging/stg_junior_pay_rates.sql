WITH source AS (
    SELECT *
    FROM {{ source('landing', 'junior_pay_rates') }}
),
junior_pay_rates_transformed AS (
    SELECT
        CASE
            WHEN age like 'Under 16%' THEN 'JPR15'
            WHEN age like 'At 16%' THEN 'JPR16'
            WHEN age like 'At 17%' THEN 'JPR17'
            WHEN age like 'At 18%' THEN 'JPR18'
            WHEN age like 'At 19%' THEN 'JPR19'
            WHEN age like 'At 20%' THEN 'JPR20'
            ELSE NULL
        END AS pay_rate_id,
        age,
        percent_of_adult_pay_rate
    FROM source
    ORDER BY pay_rate_id
)
SELECT *
FROM junior_pay_rates_transformed