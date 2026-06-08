-- ============================================================
-- Data Mart: mart_sales
-- Layer: Marts
-- Purpose: Sales analysis for business reporting
-- Source: fact_sales + dimension tables
-- Window Functions used:
--   - SUM() OVER for running totals
--   - LAG() for month over month growth
--   - RANK() for branch revenue ranking
--   - PERCENT_RANK() for revenue percentile
-- ============================================================

with sales as (
    -- Pull all sales from fact table
    select
        fs.sale_key,
        fs.sale_id,
        fs.gross_revenue,
        fs.net_revenue,
        fs.production_cost,
        fs.gross_profit,
        fs.discount_pct,
        fs.quantity_sold,
        fs.payment_method,
        fs.channel_name,
        fs.kpi_gross_margin_pct,

        -- Date attributes
        d.full_date,
        d.year,
        d.month_number,
        d.month_name,
        d.quarter_number,
        d.quarter_name,
        d.day_name,
        d.is_weekend,

        -- Restaurant attributes
        r.branch_name,
        r.restaurant_key,

        -- Menu item attributes
        m.product_name,
        m.product_category

    from {{ ref('fact_sales') }} fs
    left join {{ ref('dim_date') }} d on d.date_key = fs.date_key
    left join {{ ref('dim_restaurant') }} r on r.restaurant_key = fs.restaurant_key
    left join {{ ref('dim_menu_item') }} m on m.menu_item_key = fs.menu_item_key
),

-- ============================================================
-- Monthly revenue per branch
-- Used as base for window function calculations
-- ============================================================
monthly_revenue as (
    select
        year,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        branch_name,

        -- Total revenue metrics per branch per month
        sum(gross_revenue)                          as monthly_gross_revenue,
        sum(net_revenue)                            as monthly_net_revenue,
        sum(gross_profit)                           as monthly_gross_profit,
        sum(quantity_sold)                          as monthly_quantity_sold,
        count(sale_id)                              as monthly_transaction_count,
        avg(kpi_gross_margin_pct)                   as avg_gross_margin_pct

    from sales
    group by year, month_number, month_name, quarter_number, quarter_name, branch_name
),

-- ============================================================
-- Window functions applied on monthly revenue
-- ============================================================
revenue_with_windows as (
    select
        year,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        branch_name,
        monthly_gross_revenue,
        monthly_net_revenue,
        monthly_gross_profit,
        monthly_quantity_sold,
        monthly_transaction_count,
        avg_gross_margin_pct,

        -- --------------------------------------------------------
        -- Window Function 1: Running total of net revenue per branch
        -- Resets for each branch, accumulates month by month
        -- --------------------------------------------------------
        sum(monthly_net_revenue) over (
            partition by branch_name
            order by year, month_number
        )                                           as running_total_revenue,

        -- --------------------------------------------------------
        -- Window Function 2: Previous month revenue for MoM comparison
        -- LAG looks back 1 row within the same branch partition
        -- --------------------------------------------------------
        lag(monthly_net_revenue) over (
            partition by branch_name
            order by year, month_number
        )                                           as prev_month_revenue,

        -- --------------------------------------------------------
        -- Window Function 3: Month over month growth percentage
        -- Formula: (current - previous) / previous * 100
        -- --------------------------------------------------------
        round(
            (monthly_net_revenue - lag(monthly_net_revenue) over (
                partition by branch_name
                order by year, month_number
            )) /
            nullif(lag(monthly_net_revenue) over (
                partition by branch_name
                order by year, month_number
            ), 0) * 100
        , 2)                                        as mom_growth_pct,

        -- --------------------------------------------------------
        -- Window Function 4: Branch revenue rank per month
        -- RANK gives same rank for ties, skips next rank
        -- --------------------------------------------------------
        rank() over (
            partition by year, month_number
            order by monthly_net_revenue desc
        )                                           as branch_revenue_rank,

        -- --------------------------------------------------------
        -- Window Function 5: Revenue percentile across all months
        -- 1.0 = highest revenue, 0.0 = lowest revenue
        -- --------------------------------------------------------
        round(
            percent_rank() over (
                order by monthly_net_revenue
            )
        , 4)                                        as revenue_percentile

    from monthly_revenue
),

-- ============================================================
-- Top selling products per branch
-- ============================================================
product_sales as (
    select
        branch_name,
        product_name,
        product_category,
        sum(quantity_sold)                          as total_quantity_sold,
        sum(net_revenue)                            as total_product_revenue,

        -- --------------------------------------------------------
        -- Window Function 6: Product rank within each branch
        -- ROW_NUMBER gives unique rank even for ties
        -- --------------------------------------------------------
        row_number() over (
            partition by branch_name
            order by sum(net_revenue) desc
        )                                           as product_rank_in_branch

    from sales
    group by branch_name, product_name, product_category
),

top_products as (
    -- Keep only top 3 products per branch
    select * from product_sales
    where product_rank_in_branch <= 3
)

-- ============================================================
-- Final output — combine all CTEs
-- ============================================================
select
    -- Monthly revenue metrics
    r.year,
    r.month_number,
    r.month_name,
    r.quarter_number,
    r.quarter_name,
    r.branch_name,
    r.monthly_gross_revenue,
    r.monthly_net_revenue,
    r.monthly_gross_profit,
    r.monthly_quantity_sold,
    r.monthly_transaction_count,
    r.avg_gross_margin_pct,

    -- Window function results
    r.running_total_revenue,
    r.prev_month_revenue,
    r.mom_growth_pct,
    r.branch_revenue_rank,
    r.revenue_percentile

from revenue_with_windows r
order by r.branch_name, r.year, r.month_number