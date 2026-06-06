-- Staging model for orders
-- Source: stg_orders table in MySQL
-- Purpose: Read raw orders data as a clean view

with source as (
    select * from {{ source('staging', 'stg_orders') }}
),

renamed as (
    select
        order_id,
        order_date,
        year,
        month,
        quarter,
        branch_id,
        branch_name,
        channel_id,
        channel_name,
        status_id,
        order_status,
        product_id,
        product_name,
        quantity,
        unit_price,
        discount_pct,
        subtotal,
        employee_id,
        payment_method_id,
        payment_method,
        preparation_time_min,
        kpi_avg_ticket,
        kpi_service_time_min,
        kpi_cancellation_rate,
        loaded_at
    from source
)

select * from renamed