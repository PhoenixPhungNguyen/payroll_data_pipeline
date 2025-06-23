{{
    config(
        materialized='incremental',
        unique_key='allowance_pk',
        incremental_strategy='merge',
    )
}}
WITH allowances AS (
    SELECT *
    FROM {{ ref('stg_allowances') }}
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
allowances_joined AS (
    SELECT
        a.allowance_id AS allowance_pk,
        e.employee_pk AS employee_fk,
        c.contract_pk AS contract_fk,
        a.allowance_type,
        a.allowance_amount,
        a.allowance_start_date,
        a.allowance_end_date,
        TO_NUMBER(TO_CHAR(a.allowance_start_date, 'YYYYMMDD')) AS allowance_start_date_fk,
        TO_NUMBER(TO_CHAR(a.allowance_end_date, 'YYYYMMDD')) AS allowance_end_date_fk,
        CASE
            WHEN lower(c.payment_frequency) = 'weekly' then d.pay_period_week
            WHEN lower(c.payment_frequency) = 'fortnightly' then d.pay_period_fortnight
            WHEN lower(c.payment_frequency) = 'monthly' then d.pay_period_month
            ELSE NULL
        END AS pay_period_fk
    FROM allowances a
    LEFT JOIN employees e
        ON a.employee_id = e.employee_id
    LEFT JOIN contracts c
        ON a.employee_id = c.employee_id
        AND a.allowance_start_date BETWEEN c.start_date AND COALESCE(c.end_date, '9999-12-31')
    LEFT JOIN dates d
        ON a.allowance_start_date = d.date
    WHERE e.dbt_valid_to IS NULL
    AND c.dbt_valid_to IS NULL
)
SELECT *
FROM allowances_joined