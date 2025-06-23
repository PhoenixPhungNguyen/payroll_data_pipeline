{{
    config(
        materialized='incremental',
        unique_key='holiday_pk',
    )
}}
WITH holidays AS (
    SELECT
        CONCAT(TO_CHAR(holiday_date, 'YYYYMMDD'), '_', REPLACE(LOWER(jurisdiction), ' ', '_')) AS holiday_pk,
        holiday_date,
        holiday_name,
        information,
        reference_url,
        jurisdiction,
        day_of_week
    FROM {{ ref('stg_holidays') }}
)
SELECT *
FROM holidays