-- ============================================================
-- Dimension: dim_restaurant
-- Layer: DWH
-- Purpose: One row per unique restaurant branch
-- Grain: One row per branch
-- Note: This dimension will be used for SCD Type 2 via
--       dbt snapshots to track changes in branch information over time
-- ============================================================

with source as (
    -- Pull distinct branches from ODS orders
    -- We use orders as the source because it has the most
    -- complete branch information
    select distinct
        branch_id,
        branch_name
    from {{ ref('ods_orders') }}
),

final as (
    select
        -- --------------------------------------------------------
        -- Surrogate Key
        -- Auto-incremented integer — not the natural key
        -- This is the key that fact tables will reference
        -- --------------------------------------------------------
        row_number() over (order by branch_id)  as restaurant_key,

        -- --------------------------------------------------------
        -- Natural Key
        -- The original ID from the source system
        -- --------------------------------------------------------
        branch_id,

        -- --------------------------------------------------------
        -- Descriptive attributes
        -- --------------------------------------------------------
        branch_name,

        -- --------------------------------------------------------
        -- SCD Type 2 fields
        -- These fields track when a record was valid
        -- valid_from: when this version of the record became active
        -- valid_to: when this version of the record expired
        -- is_current: 1 if this is the current active record
        -- --------------------------------------------------------
        cast('2022-01-01' as date)              as valid_from,
        cast('9999-12-31' as date)              as valid_to,
        1                                       as is_current

    from source
)

select * from final