-- ODS model for sales
-- Source: stg_sales view
-- Purpose: Clean, standardize and translate sales data

with source as (
    select * from {{ ref('stg_sales') }}
),

cleaned as (
    select
        -- IDs
        cast(sale_id as char)                           as sale_id,
        cast(order_id as char)                          as order_id,
        cast(branch_id as unsigned)                     as branch_id,
        cast(channel_id as unsigned)                    as channel_id,
        cast(product_id as unsigned)                    as product_id,
        cast(payment_method_id as unsigned)             as payment_method_id,

        -- Dates
        cast(sale_date as date)                         as sale_date,
        cast(year as unsigned)                          as year,
        cast(month as unsigned)                         as month,
        cast(quarter as unsigned)                       as quarter,

        -- Dimensions
        branch_name,

        -- Translate channel from Spanish to English
        case channel_name
            when 'Local'    then 'In-Store'
            when 'Telefono' then 'Phone'
            else channel_name
        end                                             as channel_name,

        product_name,

        -- Translate payment method from Spanish to English
        case payment_method
            when 'Tarjeta Crédito' then 'Credit Card'
            when 'Tarjeta Débito'  then 'Debit Card'
            when 'Yape/Plin'       then 'Mobile Payment'
            when 'Efectivo'        then 'Cash'
            else payment_method
        end                                             as payment_method,

        -- Metrics
        cast(quantity_sold as unsigned)                 as quantity_sold,
        cast(unit_price as decimal(10,2))               as unit_price,
        cast(discount_pct as decimal(5,2))              as discount_pct,
        cast(gross_revenue as decimal(10,2))            as gross_revenue,
        cast(net_revenue as decimal(10,2))              as net_revenue,
        cast(production_cost as decimal(10,2))          as production_cost,
        cast(kpi_gross_margin_pct as decimal(5,2))      as kpi_gross_margin_pct,
        cast(kpi_net_revenue as decimal(10,2))          as kpi_net_revenue,
        cast(kpi_avg_ticket as decimal(10,2))           as kpi_avg_ticket,

        -- Audit
        loaded_at

    from source
    where sale_id is not null
)

select * from cleaned