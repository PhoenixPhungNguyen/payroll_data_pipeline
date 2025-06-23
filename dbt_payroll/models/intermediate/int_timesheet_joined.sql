
WITH timesheet AS (
    SELECT *
    FROM {{ ref('stg_timesheet') }}
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
timesheet_joined AS (
    SELECT
        t.timesheet_id AS timesheet_pk,
        e.employee_pk AS employee_fk,
        c.contract_pk AS contract_fk,
        t.timesheet_transaction_date,
        TO_NUMBER(TO_CHAR(t.timesheet_transaction_date, 'YYYYMMDD')) AS timesheet_transaction_date_fk,
        t.start_time,
        t.end_time,
        t.timesheet_transaction_hours,
        CASE
            WHEN lower(c.payment_frequency) = 'weekly' then d.pay_period_week
            WHEN lower(c.payment_frequency) = 'fortnightly' then d.pay_period_fortnight
            WHEN lower(c.payment_frequency) = 'monthly' then d.pay_period_month
            ELSE NULL
        END AS pay_period_fk
    FROM timesheet t
    LEFT JOIN employees e
        ON t.employee_id = e.employee_id
    LEFT JOIN contracts c
        ON t.employee_id = c.employee_id
        AND t.timesheet_transaction_date BETWEEN c.start_date AND COALESCE(c.end_date, '9999-12-31')
    LEFT JOIN dates d
        ON t.timesheet_transaction_date = d.date
    WHERE e.dbt_valid_to IS NULL
    AND c.dbt_valid_to IS NULL
)
SELECT *
FROM timesheet_joined