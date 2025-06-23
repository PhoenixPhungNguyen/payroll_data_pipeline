WITH source AS (
    SELECT *
    FROM {{ source('landing', 'past_payslips') }}
),
past_payslips_transformed AS (
    SELECT
        CONCAT('PS', employee_id, '_', pay_period) as payslip_id,
        employee_id,
        name,
        gender,
        location,
        hire_date,
        status,
        pay_period,
        start_period,
        end_period,
        total_earnings,
        tax,
        superannuation,
        accrued_leave,
        used_leave,
        balance_leave,
        total_hours_worked,
        net_pay
    FROM source
    ORDER BY employee_id, pay_period
)
SELECT *
FROM past_payslips_transformed