{{
    config(
        materialized='table'
    )
}}

with base as (
    select
        date,
        pay_period_month,
        pay_period_fortnight,
        pay_period_week,
        calendar_month,
        calendar_month_start_date,
        calendar_month_end_date
    from {{ ref('dim_dates') }}
),

monthly as (
    select
        pay_period_month as pay_period_pk,
        min(date) as period_start_date,
        max(date) as period_end_date,
        dateadd(day, 1, max(date)) as payday,
        'Monthly' as frequency,
        concat(monthname(min(date)), ' ', year(min(date))) as pay_period_label
    from base
    group by pay_period_month
),

fortnightly as (
    select
        pay_period_fortnight as pay_period_pk,
        min(date) as period_start_date,
        max(date) as period_end_date,
        dateadd(day, 1, max(date)) as payday,
        'Fortnightly' as frequency,
        concat('Fortnight ', right(pay_period_fortnight, 2), ' ', monthname(min(date)), ' ', year(min(date))) as pay_period_label
    from base
    group by pay_period_fortnight
),

weekly as (
    select
        pay_period_week as pay_period_pk,
        min(date) as period_start_date,
        max(date) as period_end_date,
        dateadd(day, 1, max(date)) as payday,
        'Weekly' as frequency,
        concat('Week ', right(pay_period_week, 2), ' ', monthname(min(date)), ' ', year(min(date))) as pay_period_label
    from base
    group by pay_period_week
)

select * from monthly
union all
select * from fortnightly
union all
select * from weekly
