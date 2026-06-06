-- ============================================================
-- Dimension: dim_employee
-- Layer: DWH
-- Purpose: One row per unique employee
-- Grain: One row per employee
-- Note: This dimension will be used for SCD Type 2 via
--       dbt snapshots to track changes in employee information over time
-- ============================================================

with source as (
    -- Pull all employees from ODS layer
    -- ODS already has cleaned and translated data
    select
        employee_id,
        first_name,
        last_name,
        full_name,
        branch_id,
        branch_name,
        role_id,
        role_name,
        shift_id,
        shift_name,
        hire_date,
        base_salary,
        years_experience
    from {{ ref('ods_employees') }}
),

final as (
    select
        -- --------------------------------------------------------
        -- Surrogate Key
        -- Auto-incremented integer — not the natural key
        -- This is the key that fact tables will reference
        -- --------------------------------------------------------
        row_number() over (order by employee_id)    as employee_key,

        -- --------------------------------------------------------
        -- Natural Key
        -- The original ID from the source system
        -- --------------------------------------------------------
        employee_id,

        -- --------------------------------------------------------
        -- Descriptive attributes
        -- --------------------------------------------------------
        first_name,
        last_name,
        full_name,
        branch_id,
        branch_name,
        role_id,
        role_name,
        shift_id,
        shift_name,
        hire_date,
        base_salary,
        years_experience,

        -- --------------------------------------------------------
        -- SCD Type 2 fields
        -- These fields track when a record was valid
        -- valid_from: when this version of the record became active
        -- valid_to: when this version of the record expired
        -- is_current: 1 if this is the current active record
        -- --------------------------------------------------------
        cast('2022-01-01' as date)                  as valid_from,
        cast('9999-12-31' as date)                  as valid_to,
        1                                           as is_current

    from source
)

select * from final