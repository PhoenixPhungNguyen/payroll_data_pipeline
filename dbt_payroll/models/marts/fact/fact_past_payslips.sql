{{
    config(
        materialized='incremental',
        unique_key='payslip_pk',
        incremental_strategy='merge',
    )
}}
WITH past_payslips AS (
    SELECT *
    FROM {{ ref('stg_past_payslips') }}
),
employees AS (
    SELECT *
    FROM {{ ref('dim_employees') }}
),
past_payslips_joined AS (
    SELECT
        p.payslip_id AS payslip_pk,
        e.employee_pk AS employee_fk,
        p.employee_id,
        p.name,
        p.gender,
        p.location,
        p.hire_date,
        TO_NUMBER(TO_CHAR(p.hire_date, 'YYYYMMDD')) AS hire_date_fk,
        p.status,
        p.pay_period AS pay_period_fk,
        p.start_period,
        TO_NUMBER(TO_CHAR(p.start_period, 'YYYYMMDD')) AS start_period_fk,
        p.end_period,
        TO_NUMBER(TO_CHAR(p.end_period, 'YYYYMMDD')) AS end_period_fk,
        CAST(REGEXP_REPLACE(p.total_earnings, '[^0-9.]', '') AS NUMERIC(18,2)) AS total_earnings,
        CAST(REGEXP_REPLACE(p.tax, '[^0-9.]', '') AS NUMERIC(18,2)) AS tax,
        CAST(REGEXP_REPLACE(p.superannuation, '[^0-9.]', '') AS NUMERIC(18,2)) AS superannuation,
        p.accrued_leave,
        p.used_leave,
        p.balance_leave,
        p.total_hours_worked,
        CAST(REGEXP_REPLACE(p.net_pay, '[^0-9.]', '') AS NUMERIC(18,2)) AS net_pay
    FROM past_payslips p
    LEFT JOIN employees e
        ON p.employee_id = e.employee_id
    WHERE e.dbt_valid_to IS NULL
)
SELECT *
FROM past_payslips_joined