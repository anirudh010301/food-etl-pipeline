-- Staging model for employees
-- Source: stg_employees table in MySQL
-- Purpose: Read raw employees data as a clean view

with source as (
    select * from {{ source('staging', 'stg_employees') }}
),

renamed as (
    select
        employee_id,
        first_name,
        last_name,
        branch_id,
        branch_name,
        role_id,
        role_name,
        shift_id,
        shift_name,
        hire_date,
        base_salary,
        years_experience,
        annual_absence_days,
        orders_attended,
        customer_rating,
        kpi_productivity,
        kpi_satisfaction,
        kpi_attendance_pct,
        loaded_at
    from source
)

select * from renamed
