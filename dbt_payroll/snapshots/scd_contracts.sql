{% snapshot scd_contracts %}
{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='contract_id',
        strategy='check',
        check_cols=[
            'employee_id',
            'start_date',
            'end_date',
            'pay_rate',
            'job_title',
            'payment_frequency',
            'contract_type',
            'employment_type',
            'contract_status'
        ],
        hard_deletes='invalidate'
    )
}}
SELECT *
FROM {{ ref('stg_contracts') }}
{% endsnapshot %}