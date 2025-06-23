{% snapshot scd_employees %}
{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='employee_id',
        strategy='check',
        check_cols=[
            'employee_first_name',
            'employee_middle_name',
            'employee_last_name',
            'employee_gender',
            'employee_location',
            'date_of_birth',
            'hire_date',
            'termination_date',
            'employee_status'
        ],
        hard_deletes='invalidate'
    )
}}
SELECT *
FROM {{ ref('stg_employees') }}
{% endsnapshot %}