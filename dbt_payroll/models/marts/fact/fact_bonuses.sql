{{
    config(
        materialized='incremental',
        unique_key='bonus_pk',
        incremental_strategy='merge',
    )
}}
WITH bonuses AS (
    SELECT *
    FROM {{ ref('stg_bonuses') }}
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
bonuses_joined AS (
    SELECT
        b.bonus_id AS bonus_pk,
        e.employee_pk AS employee_fk,
        c.contract_pk AS contract_fk,
        b.bonus_type,
        b.bonus_amount,
        b.bonus_date,
        TO_NUMBER(TO_CHAR(b.bonus_date, 'YYYYMMDD')) AS bonus_date_fk,
        CASE
            WHEN lower(c.payment_frequency) = 'weekly' then d.pay_period_week
            WHEN lower(c.payment_frequency) = 'fortnightly' then d.pay_period_fortnight
            WHEN lower(c.payment_frequency) = 'monthly' then d.pay_period_month
            ELSE NULL
        END AS pay_period_fk
    FROM bonuses b
    LEFT JOIN employees e
        ON b.employee_id = e.employee_id
    LEFT JOIN contracts c
        ON b.employee_id = c.employee_id
        AND b.bonus_date BETWEEN c.start_date AND COALESCE(c.end_date, '9999-12-31')
    LEFT JOIN dates d
        ON b.bonus_date = d.date
    WHERE e.dbt_valid_to IS NULL
    AND c.dbt_valid_to IS NULL
)
SELECT *
FROM bonuses_joined