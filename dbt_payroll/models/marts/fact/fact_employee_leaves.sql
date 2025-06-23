{{
    config(
        materialized='incremental',
        unique_key='leave_pk',
        incremental_strategy='merge',
    )
}}
WITH employee_leaves AS (
    SELECT *
    FROM {{ ref('stg_employee_leaves') }}
),
employees AS (
    SELECT *
    FROM {{ ref('dim_employees') }}
),
contracts AS (
    SELECT *
    FROM {{ ref('dim_contracts') }}
),
dates as (
    SELECT
        date,
        pay_period_week,
        pay_period_fortnight,
        pay_period_month
    FROM {{ ref('dim_dates') }}
),
employee_leaves_joined AS (
    SELECT
        l.leave_id AS leave_pk,
        e.employee_pk AS employee_fk,
        c.contract_pk AS contract_fk,
        l.leave_type,
        l.leave_start_date,
        l.leave_end_date,
        TO_NUMBER(TO_CHAR(l.leave_start_date, 'YYYYMMDD')) AS leave_start_date_fk,
        TO_NUMBER(TO_CHAR(l.leave_end_date, 'YYYYMMDD')) AS leave_end_date_fk,
        leave_hours,
        CASE
            WHEN lower(c.payment_frequency) = 'weekly' then d.pay_period_week
            WHEN lower(c.payment_frequency) = 'fortnightly' then d.pay_period_fortnight
            WHEN lower(c.payment_frequency) = 'monthly' then d.pay_period_month
            ELSE NULL
        END AS pay_period_fk
    FROM employee_leaves l
    LEFT JOIN employees e
        ON l.employee_id = e.employee_id
    LEFT JOIN contracts c
        ON l.employee_id = c.employee_id
        AND l.leave_start_date BETWEEN c.start_date AND COALESCE(c.end_date, '9999-12-31')
    LEFT JOIN dates d
        ON l.leave_start_date = d.date
    WHERE e.dbt_valid_to IS NULL
    AND c.dbt_valid_to IS NULL
)
SELECT *
FROM employee_leaves_joined