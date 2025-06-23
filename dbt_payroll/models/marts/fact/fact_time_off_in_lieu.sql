{{
    config(
        materialized='incremental',
        unique_key='toil_pk',
        incremental_strategy='merge',
    )
}}
WITH time_off_in_lieu AS (
    SELECT *
    FROM {{ ref('stg_time_off_in_lieu') }}
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
time_off_in_lieu_joined AS (
    SELECT
        t.toil_id AS toil_pk,
        e.employee_pk AS employee_fk,
        c.contract_pk AS contract_fk,
        t.overtime_date,
        TO_NUMBER(TO_CHAR(t.overtime_date, 'YYYYMMDD')) AS overtime_date_fk,
        t.toil_hours_accrued,
        t.toil_usage_date,
        TO_NUMBER(TO_CHAR(t.toil_usage_date, 'YYYYMMDD')) AS toil_usage_date_fk,
        CASE
            WHEN lower(c.payment_frequency) = 'weekly' then d.pay_period_week
            WHEN lower(c.payment_frequency) = 'fortnightly' then d.pay_period_fortnight
            WHEN lower(c.payment_frequency) = 'monthly' then d.pay_period_month
            ELSE NULL
        END AS pay_period_fk
    FROM time_off_in_lieu t
    LEFT JOIN employees e
        ON t.employee_id = e.employee_id
    LEFT JOIN contracts c
        ON t.employee_id = c.employee_id
        AND t.overtime_date BETWEEN c.start_date AND COALESCE(c.end_date, '9999-12-31')
    LEFT JOIN dates d
        ON t.overtime_date = d.date
    WHERE e.dbt_valid_to IS NULL
    AND c.dbt_valid_to IS NULL
)
SELECT *
FROM time_off_in_lieu_joined