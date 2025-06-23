{{
    config(
        materialized='incremental',
        unique_key='contract_pk',
    )
}}
WITH employees AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['contract_id','dbt_valid_from']) }} AS contract_pk,
        contract_id,
        employee_id,
        start_date,
        end_date,
        pay_rate,
        job_title,
        payment_frequency,
        contract_type,
        employment_type,
        contract_status,
        dbt_valid_from,
        dbt_valid_to
    FROM {{ ref('scd_contracts') }}
)
SELECT *
FROM employees
{% if is_incremental() %}
WHERE dbt_valid_from > (SELECT MAX(dbt_valid_from) FROM {{ this }})
{% endif %}