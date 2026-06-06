-- ============================================================
-- Fact Table: fact_orders
-- Layer: DWH
-- Purpose: One row per order — captures all order transactions
-- Grain: One row per order
-- Dimensions: dim_date, dim_restaurant, dim_employee, 
--             dim_menu_item
-- ============================================================

with orders as (
    -- Pull cleaned orders from ODS layer
    select * from {{ ref('ods_orders') }}
),

dim_date as (
    -- Pull date dimension for joining
    select * from {{ ref('dim_date') }}
),

dim_restaurant as (
    -- Pull restaurant dimension — only current records
    select * from {{ ref('dim_restaurant') }}
    where is_current = 1
),

dim_employee as (
    -- Pull employee dimension — only current records
    select * from {{ ref('dim_employee') }}
    where is_current = 1
),

dim_menu_item as (
    -- Pull menu item dimension
    select * from {{ ref('dim_menu_item') }}
),

final as (
    select
        -- --------------------------------------------------------
        -- Surrogate Key
        -- Unique identifier for each row in this fact table
        -- --------------------------------------------------------
        row_number() over (order by o.order_id)         as order_key,

        -- --------------------------------------------------------
        -- Foreign Keys — links to dimension tables
        -- --------------------------------------------------------

        -- Link to dim_date using YYYYMMDD format
        d.date_key,

        -- Link to dim_restaurant
        r.restaurant_key,

        -- Link to dim_employee
        e.employee_key,

        -- Link to dim_menu_item
        m.menu_item_key,

        -- --------------------------------------------------------
        -- Degenerate Dimension
        -- order_id is kept in fact table as it has no dimension
        -- table of its own but is useful for filtering/grouping
        -- --------------------------------------------------------
        o.order_id,

        -- --------------------------------------------------------
        -- Measures — the numeric facts we analyze
        -- --------------------------------------------------------

        -- Quantity ordered
        o.quantity,

        -- Price per unit before discount
        o.unit_price,

        -- Discount percentage applied
        o.discount_pct,

        -- Discount amount in currency
        round(o.unit_price * o.quantity * o.discount_pct / 100, 2)  as discount_amount,

        -- Total amount after discount
        o.subtotal,

        -- Time taken to prepare the order in minutes
        o.preparation_time_min,

        -- --------------------------------------------------------
        -- KPI Measures
        -- --------------------------------------------------------
        o.kpi_avg_ticket,
        o.kpi_service_time_min,
        o.kpi_cancellation_rate,

        -- --------------------------------------------------------
        -- Descriptive attributes kept for convenience
        -- --------------------------------------------------------
        o.order_status,
        o.payment_method,
        o.channel_name_en                               as channel_name,

        -- --------------------------------------------------------
        -- Audit
        -- --------------------------------------------------------
        o.loaded_at

    from orders o

    -- Join to dim_date using YYYYMMDD integer key
    left join dim_date d
        on d.full_date = o.order_date

    -- Join to dim_restaurant using natural key
    left join dim_restaurant r
        on r.branch_id = o.branch_id

    -- Join to dim_employee using natural key
    left join dim_employee e
        on e.employee_id = cast(o.employee_id as char)

    -- Join to dim_menu_item using natural key
    left join dim_menu_item m
        on m.product_id = o.product_id
)

select * from final