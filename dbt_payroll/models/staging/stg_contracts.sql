WITH source AS (
    SELECT *
    FROM {{ source('landing', 'contract_details') }}
),
contracts_transformed AS (
    SELECT
        contract_id,
        employee_id,
        start_date,
        end_date,
        pay_rate,
        job_title,
        payment_frequency,
        contract_type,
        employment_type,
        contract_status
    FROM source
    ORDER BY start_date
)
SELECT *
FROM contracts_transformed