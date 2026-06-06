-- ODS model for employees
-- Source: stg_employees view
-- Purpose: Clean, standardize and translate employees data

with source as (
    select * from {{ ref('stg_employees') }}
),

cleaned as (
    select
        -- IDs
        cast(employee_id as char)                       as employee_id,
        cast(branch_id as unsigned)                     as branch_id,
        cast(role_id as unsigned)                       as role_id,
        cast(shift_id as unsigned)                      as shift_id,

        -- Names
        first_name,
        last_name,
        concat(first_name, ' ', last_name)              as full_name,
        branch_name,

        -- Translate role from Spanish to English
        case role_name
            when 'Cajero'               then 'Cashier'
            when 'Delivery'             then 'Delivery Driver'
            when 'Atención al cliente'  then 'Customer Service'
            when 'Supervisor de turno'  then 'Shift Supervisor'
            when 'Gerente de sede'      then 'Branch Manager'
            when 'Cocinero'             then 'Cook'
            else role_name
        end                                             as role_name,

        -- Translate shift from Spanish to English
        case shift_name
            when 'Mañana (8-16h)'   then 'Morning (8-16h)'
            when 'Tarde (14-22h)'   then 'Afternoon (14-22h)'
            when 'Noche (18-02h)'   then 'Night (18-02h)'
            else shift_name
        end                                             as shift_name,

        -- Dates
        cast(hire_date as date)                         as hire_date,

        -- Metrics
        cast(base_salary as decimal(10,2))              as base_salary,
        cast(years_experience as decimal(5,2))          as years_experience,
        cast(annual_absence_days as decimal(5,2))       as annual_absence_days,
        cast(orders_attended as unsigned)               as orders_attended,
        cast(customer_rating as decimal(3,2))           as customer_rating,
        cast(kpi_productivity as decimal(10,2))         as kpi_productivity,
        cast(kpi_satisfaction as decimal(3,2))          as kpi_satisfaction,
        cast(kpi_attendance_pct as decimal(5,2))        as kpi_attendance_pct,

        -- Audit
        loaded_at

    from source
    where employee_id is not null
)

select * from cleaned