-- ============================================================
-- Dimension: dim_menu_item
-- Layer: DWH
-- Purpose: One row per unique menu item/product
-- Grain: One row per product
-- Source: ods_orders (contains product information)
-- ============================================================

with source as (
    -- Pull distinct products from ODS orders
    -- Each product has a unique product_id and product_name
    select distinct
        product_id,
        product_name
    from {{ ref('ods_orders') }}
),

final as (
    select
        -- --------------------------------------------------------
        -- Surrogate Key
        -- Auto-incremented integer — not the natural key
        -- This is the key that fact tables will reference
        -- --------------------------------------------------------
        row_number() over (order by product_id)     as menu_item_key,

        -- --------------------------------------------------------
        -- Natural Key
        -- The original product ID from the source system
        -- --------------------------------------------------------
        product_id,

        -- --------------------------------------------------------
        -- Descriptive attributes
        -- --------------------------------------------------------
        product_name,

        -- --------------------------------------------------------
        -- Derived attributes
        -- Extract category from product name
        -- In our dataset products follow naming conventions
        -- that allow us to derive a category
        -- --------------------------------------------------------
        case
            when lower(product_name) like '%burger%'    then 'Burger'
            when lower(product_name) like '%combo%'     then 'Combo'
            when lower(product_name) like '%drink%'     then 'Drink'
            when lower(product_name) like '%fries%'     then 'Sides'
            when lower(product_name) like '%chicken%'   then 'Chicken'
            when lower(product_name) like '%salad%'     then 'Salad'
            when lower(product_name) like '%dessert%'   then 'Dessert'
            else 'Other'
        end                                             as product_category,

        -- --------------------------------------------------------
        -- Availability flag
        -- All products in our dataset are active/available
        -- --------------------------------------------------------
        1                                               as is_available

    from source
)

select * from final