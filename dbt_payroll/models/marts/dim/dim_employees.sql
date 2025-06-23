{{
    config(
        materialized='incremental',
        unique_key='employee_pk'
    )
}}
WITH employees AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['employee_id','dbt_valid_from']) }} AS employee_pk,
        employee_id,
        employee_first_name,
        employee_middle_name,
        employee_last_name,
        employee_gender,
        employee_location,
        date_of_birth,
        hire_date,
        termination_date,
        employee_status,
        dbt_valid_from,
        dbt_valid_to
    FROM {{ ref('scd_employees') }}
)
SELECT *
FROM employees
{% if is_incremental() %}
WHERE dbt_valid_from > (SELECT MAX(dbt_valid_from) FROM {{ this }})
{% endif %}