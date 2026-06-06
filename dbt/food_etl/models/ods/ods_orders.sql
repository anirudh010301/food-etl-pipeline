-- ODS model for orders
-- Source: stg_orders view
-- Purpose: Clean, standardize and translate orders data

with source as (
    select * from {{ ref('stg_orders') }}
),

cleaned as (
    select
        -- IDs
        cast(order_id as char)                          as order_id,
        cast(branch_id as unsigned)                     as branch_id,
        cast(channel_id as unsigned)                    as channel_id,
        cast(status_id as unsigned)                     as status_id,
        cast(product_id as unsigned)                    as product_id,
        cast(employee_id as unsigned)                   as employee_id,
        cast(payment_method_id as unsigned)             as payment_method_id,

        -- Dates
        cast(order_date as date)                        as order_date,
        cast(year as unsigned)                          as year,
        cast(month as unsigned)                         as month,
        cast(quarter as unsigned)                       as quarter,

        -- Dimensions
        branch_name,
        channel_name,

        -- Translate order status from Spanish to English
        case order_status
            when 'Entregado'      then 'Delivered'
            when 'Cancelado'      then 'Cancelled'
            when 'En preparación' then 'In Preparation'
            when 'En camino'      then 'On The Way'
            else order_status
        end                                             as order_status,

        product_name,

        -- Translate payment method from Spanish to English
        case payment_method
            when 'Tarjeta Crédito' then 'Credit Card'
            when 'Tarjeta Débito'  then 'Debit Card'
            when 'Yape/Plin'       then 'Mobile Payment'
            when 'Efectivo'        then 'Cash'
            else payment_method
        end                                             as payment_method,

        -- Translate channel from Spanish to English
        case channel_name
            when 'Local'    then 'In-Store'
            when 'Telefono' then 'Phone'
            else channel_name
        end                                             as channel_name_en,

        -- Metrics
        cast(quantity as unsigned)                      as quantity,
        cast(unit_price as decimal(10,2))               as unit_price,
        cast(discount_pct as decimal(5,2))              as discount_pct,
        cast(subtotal as decimal(10,2))                 as subtotal,
        cast(preparation_time_min as unsigned)          as preparation_time_min,
        cast(kpi_avg_ticket as decimal(10,2))           as kpi_avg_ticket,
        cast(kpi_service_time_min as decimal(10,2))     as kpi_service_time_min,
        cast(kpi_cancellation_rate as decimal(5,2))     as kpi_cancellation_rate,

        -- Audit
        loaded_at

    from source
    where order_id is not null
)

select * from cleaned