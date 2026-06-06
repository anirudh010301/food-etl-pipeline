-- Staging model for sales
-- Source: stg_sales table in MySQL
-- Purpose: Read raw sales data as a clean view

with source as (
    select * from {{ source('staging', 'stg_sales') }}
),

renamed as (
    select
        sale_id,
        sale_date,
        year,
        month,
        quarter,
        order_id,
        branch_id,
        branch_name,
        channel_id,
        channel_name,
        product_id,
        product_name,
        quantity_sold,
        unit_price,
        discount_pct,
        gross_revenue,
        net_revenue,
        production_cost,
        payment_method_id,
        payment_method,
        kpi_gross_margin_pct,
        kpi_net_revenue,
        kpi_avg_ticket,
        loaded_at
    from source
)

select * from renamed