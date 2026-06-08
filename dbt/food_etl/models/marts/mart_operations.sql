-- ============================================================
-- Data Mart: mart_operations
-- Layer: Marts
-- Purpose: Operational analysis for business reporting
-- Source: fact_orders + dimension tables
-- Window Functions used:
--   - AVG() OVER for 7 day moving average
--   - RANK() for branch performance ranking
--   - ROW_NUMBER() for top performers
--   - SUM() OVER for running order counts
-- ============================================================

with orders as (
    -- Pull all orders from fact table with dimension attributes
    select
        fo.order_key,
        fo.order_id,
        fo.quantity,
        fo.subtotal,
        fo.discount_pct,
        fo.discount_amount,
        fo.preparation_time_min,
        fo.order_status,
        fo.payment_method,
        fo.channel_name,
        fo.kpi_cancellation_rate,

        -- Date attributes
        d.full_date,
        d.year,
        d.month_number,
        d.month_name,
        d.quarter_number,
        d.day_name,
        d.day_of_week_number,
        d.is_weekend,
        d.week_of_year,

        -- Restaurant attributes
        r.branch_name,

        -- Menu item attributes
        m.product_name,
        m.product_category

    from {{ ref('fact_orders') }} fo
    left join {{ ref('dim_date') }} d on d.date_key = fo.date_key
    left join {{ ref('dim_restaurant') }} r on r.restaurant_key = fo.restaurant_key
    left join {{ ref('dim_menu_item') }} m on m.menu_item_key = fo.menu_item_key
),

-- ============================================================
-- Daily order volume per branch
-- Used as base for moving average calculation
-- ============================================================
daily_orders as (
    select
        full_date,
        year,
        month_number,
        month_name,
        week_of_year,
        day_name,
        is_weekend,
        branch_name,

        -- Daily metrics
        count(order_id)                             as daily_order_count,
        sum(subtotal)                               as daily_revenue,
        avg(preparation_time_min)                   as avg_prep_time_min,
        sum(case when order_status = 'Cancelled'
            then 1 else 0 end)                      as cancelled_orders,
        sum(case when order_status = 'Delivered'
            then 1 else 0 end)                      as delivered_orders

    from orders
    group by full_date, year, month_number, month_name,
             week_of_year, day_name, is_weekend, branch_name
),

-- ============================================================
-- Window functions on daily orders
-- ============================================================
daily_with_windows as (
    select
        full_date,
        year,
        month_number,
        month_name,
        week_of_year,
        day_name,
        is_weekend,
        branch_name,
        daily_order_count,
        daily_revenue,
        avg_prep_time_min,
        cancelled_orders,
        delivered_orders,

        -- --------------------------------------------------------
        -- Window Function 1: 7 day moving average of order count
        -- ROWS BETWEEN 6 PRECEDING AND CURRENT ROW = last 7 days
        -- --------------------------------------------------------
        round(avg(daily_order_count) over (
            partition by branch_name
            order by full_date
            rows between 6 preceding and current row
        ), 2)                                       as orders_7day_moving_avg,

        -- --------------------------------------------------------
        -- Window Function 2: Running total of orders per branch
        -- Accumulates from start of data to current row
        -- --------------------------------------------------------
        sum(daily_order_count) over (
            partition by branch_name
            order by full_date
        )                                           as running_total_orders,

        -- --------------------------------------------------------
        -- Window Function 3: Branch rank by daily revenue
        -- Ranks branches against each other for each date
        -- --------------------------------------------------------
        rank() over (
            partition by full_date
            order by daily_revenue desc
        )                                           as daily_revenue_rank,

        -- --------------------------------------------------------
        -- Window Function 4: 7 day moving average of prep time
        -- Tracks whether preparation times are improving
        -- --------------------------------------------------------
        round(avg(avg_prep_time_min) over (
            partition by branch_name
            order by full_date
            rows between 6 preceding and current row
        ), 2)                                       as prep_time_7day_moving_avg

    from daily_orders
),

-- ============================================================
-- Channel performance analysis
-- ============================================================
channel_performance as (
    select
        year,
        month_number,
        channel_name,
        count(order_id)                             as order_count,
        sum(subtotal)                               as total_revenue,
        avg(preparation_time_min)                   as avg_prep_time,

        -- --------------------------------------------------------
        -- Window Function 5: Channel rank by order count per month
        -- --------------------------------------------------------
        rank() over (
            partition by year, month_number
            order by count(order_id) desc
        )                                           as channel_rank

    from orders
    group by year, month_number, channel_name
)

-- ============================================================
-- Final output
-- ============================================================
select
    d.full_date,
    d.year,
    d.month_number,
    d.month_name,
    d.week_of_year,
    d.day_name,
    d.is_weekend,
    d.branch_name,
    d.daily_order_count,
    d.daily_revenue,
    d.avg_prep_time_min,
    d.cancelled_orders,
    d.delivered_orders,
    d.orders_7day_moving_avg,
    d.running_total_orders,
    d.daily_revenue_rank,
    d.prep_time_7day_moving_avg

from daily_with_windows d
order by d.branch_name, d.full_date