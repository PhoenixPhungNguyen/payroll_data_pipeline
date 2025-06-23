{{
    config(
        materialized='incremental',
        unique_key='timesheet_pk',
        incremental_strategy='merge',
    )
}}
WITH int_timesheet_joined AS (
    SELECT *
    FROM {{ ref('int_timesheet_joined') }}
)
SELECT *
FROM int_timesheet_joined