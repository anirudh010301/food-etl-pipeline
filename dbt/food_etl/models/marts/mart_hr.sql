-- ============================================================
-- Data Mart: mart_hr
-- Layer: Marts
-- Purpose: HR and employee performance analysis
-- Source: fact_orders + dim_employee + dimension tables
-- Window Functions used:
--   - RANK() for employee performance ranking
--   - ROW_NUMBER() for top performers per branch
--   - NTILE() for performance quartiles
--   - AVG() OVER for branch average comparison
-- ============================================================

with employee_orders as (
    -- Pull all orders with employee and date information
    select
        fo.order_id,
        fo.subtotal,
        fo.preparation_time_min,
        fo.order_status,
        fo.kpi_cancellation_rate,

        -- Date attributes
        d.year,
        d.month_number,
        d.month_name,
        d.quarter_number,

        -- Employee attributes
        e.employee_key,
        e.employee_id,
        e.full_name,
        e.role_name,
        e.shift_name,
        e.branch_name,
        e.hire_date,
        e.base_salary,
        e.years_experience,

        -- Restaurant attributes
        r.branch_name                               as order_branch_name

    from {{ ref('fact_orders') }} fo
    left join {{ ref('dim_date') }} d
        on d.date_key = fo.date_key
    left join {{ ref('dim_employee') }} e
        on e.employee_key = fo.employee_key
    left join {{ ref('dim_restaurant') }} r
        on r.restaurant_key = fo.restaurant_key
),

-- ============================================================
-- Employee performance summary
-- Aggregate metrics per employee
-- ============================================================
employee_performance as (
    select
        employee_id,
        full_name,
        role_name,
        shift_name,
        branch_name,
        hire_date,
        base_salary,
        years_experience,

        -- Performance metrics
        count(order_id)                             as total_orders_handled,
        sum(subtotal)                               as total_revenue_generated,
        avg(subtotal)                               as avg_order_value,
        avg(preparation_time_min)                   as avg_prep_time_min,

        -- Cancellation rate
        round(
            sum(case when order_status = 'Cancelled'
                then 1 else 0 end) * 100.0
            / nullif(count(order_id), 0)
        , 2)                                        as cancellation_rate_pct,

        -- Delivery success rate
        round(
            sum(case when order_status = 'Delivered'
                then 1 else 0 end) * 100.0
            / nullif(count(order_id), 0)
        , 2)                                        as delivery_success_rate_pct

    from employee_orders
    group by employee_id, full_name, role_name, shift_name,
             branch_name, hire_date, base_salary, years_experience
),

-- ============================================================
-- Window functions on employee performance
-- ============================================================
performance_with_windows as (
    select
        employee_id,
        full_name,
        role_name,
        shift_name,
        branch_name,
        hire_date,
        base_salary,
        years_experience,
        total_orders_handled,
        total_revenue_generated,
        avg_order_value,
        avg_prep_time_min,
        cancellation_rate_pct,
        delivery_success_rate_pct,

        -- --------------------------------------------------------
        -- Window Function 1: Employee rank by revenue within branch
        -- RANK gives same rank for ties
        -- --------------------------------------------------------
        rank() over (
            partition by branch_name
            order by total_revenue_generated desc
        )                                           as revenue_rank_in_branch,

        -- --------------------------------------------------------
        -- Window Function 2: Employee rank by orders within branch
        -- --------------------------------------------------------
        rank() over (
            partition by branch_name
            order by total_orders_handled desc
        )                                           as orders_rank_in_branch,

        -- --------------------------------------------------------
        -- Window Function 3: Top performer flag per branch
        -- ROW_NUMBER gives unique rank — no ties
        -- --------------------------------------------------------
        row_number() over (
            partition by branch_name
            order by total_revenue_generated desc
        )                                           as row_num_in_branch,

        -- --------------------------------------------------------
        -- Window Function 4: Performance quartile across all employees
        -- NTILE(4) divides employees into 4 equal groups
        -- 1 = top 25%, 4 = bottom 25%
        -- --------------------------------------------------------
        ntile(4) over (
            order by total_revenue_generated desc
        )                                           as performance_quartile,

        -- --------------------------------------------------------
        -- Window Function 5: Branch average revenue for comparison
        -- Shows how each employee compares to their branch average
        -- --------------------------------------------------------
        round(avg(total_revenue_generated) over (
            partition by branch_name
        ), 2)                                       as branch_avg_revenue,

        -- --------------------------------------------------------
        -- Window Function 6: Revenue vs branch average difference
        -- Positive = above average, Negative = below average
        -- --------------------------------------------------------
        round(
            total_revenue_generated - avg(total_revenue_generated) over (
                partition by branch_name
            )
        , 2)                                        as revenue_vs_branch_avg

    from employee_performance
)

-- ============================================================
-- Final output
-- ============================================================
select
    employee_id,
    full_name,
    role_name,
    shift_name,
    branch_name,
    hire_date,
    base_salary,
    years_experience,
    total_orders_handled,
    total_revenue_generated,
    avg_order_value,
    avg_prep_time_min,
    cancellation_rate_pct,
    delivery_success_rate_pct,
    revenue_rank_in_branch,
    orders_rank_in_branch,

    -- Top performer flag — 1 if rank 1 in branch
    case when row_num_in_branch = 1 then 1 else 0 end   as is_top_performer,

    -- Performance quartile label
    case performance_quartile
        when 1 then 'Top 25%'
        when 2 then 'Upper Middle 25%'
        when 3 then 'Lower Middle 25%'
        when 4 then 'Bottom 25%'
    end                                                 as performance_quartile_label,

    branch_avg_revenue,
    revenue_vs_branch_avg

from performance_with_windows
order by branch_name, revenue_rank_in_branch