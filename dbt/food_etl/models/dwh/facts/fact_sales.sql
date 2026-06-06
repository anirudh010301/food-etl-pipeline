-- ============================================================
-- Fact Table: fact_sales
-- Layer: DWH
-- Purpose: One row per sale transaction
-- Grain: One row per sale
-- Dimensions: dim_date, dim_restaurant, dim_menu_item
-- ============================================================

with sales as (
    -- Pull cleaned sales from ODS layer
    select * from {{ ref('ods_sales') }}
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
        row_number() over (order by s.sale_id)          as sale_key,

        -- --------------------------------------------------------
        -- Foreign Keys — links to dimension tables
        -- --------------------------------------------------------

        -- Link to dim_date using YYYYMMDD format
        d.date_key,

        -- Link to dim_restaurant
        r.restaurant_key,

        -- Link to dim_menu_item
        m.menu_item_key,

        -- --------------------------------------------------------
        -- Degenerate Dimensions
        -- Kept in fact table as they have no dimension table
        -- but are useful for filtering/grouping
        -- --------------------------------------------------------
        s.sale_id,
        s.order_id,

        -- --------------------------------------------------------
        -- Measures — the numeric facts we analyze
        -- --------------------------------------------------------

        -- Quantity sold
        s.quantity_sold,

        -- Price per unit before discount
        s.unit_price,

        -- Discount percentage applied
        s.discount_pct,

        -- Gross revenue before any deductions
        s.gross_revenue,

        -- Net revenue after discount
        s.net_revenue,

        -- Cost to produce the items sold
        s.production_cost,

        -- Profit = net revenue - production cost
        round(s.net_revenue - s.production_cost, 2)     as gross_profit,

        -- --------------------------------------------------------
        -- KPI Measures
        -- --------------------------------------------------------
        s.kpi_gross_margin_pct,
        s.kpi_net_revenue,
        s.kpi_avg_ticket,

        -- --------------------------------------------------------
        -- Descriptive attributes kept for convenience
        -- --------------------------------------------------------
        s.payment_method,
        s.channel_name,

        -- --------------------------------------------------------
        -- Audit
        -- --------------------------------------------------------
        s.loaded_at

    from sales s

    -- Join to dim_date using YYYYMMDD integer key
    left join dim_date d
        on d.full_date = s.sale_date

    -- Join to dim_restaurant using natural key
    left join dim_restaurant r
        on r.branch_id = s.branch_id

    -- Join to dim_menu_item using natural key
    left join dim_menu_item m
        on m.product_id = s.product_id
)

select * from final