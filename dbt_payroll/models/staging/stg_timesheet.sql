WITH source AS (
    SELECT *
    FROM {{ source('landing', 'timesheet') }}
),
timesheet_transformed AS (
    SELECT
        timesheet_id,
        employee_id,
        timesheet_transaction_date,
        start_time,
        end_time,
        timesheet_transaction_hours,
        pay_period_id
    FROM source
    ORDER BY timesheet_transaction_date, start_time
)
SELECT *
FROM timesheet_transformed