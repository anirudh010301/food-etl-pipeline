-- ============================================================
-- Dimension: dim_date
-- Layer: DWH
-- Purpose: Single source of truth for all date-related analysis
--          Every fact table joins to this dimension via date_key
-- Covers: 2022-01-01 to 2025-12-31 (matches our dataset range)
-- Grain: One row per calendar day
-- ============================================================

with date_spine as (
    -- Generate one row for every day between 2022-01-01 and 2025-12-31
    -- Using 4 cross joined sets to generate up to 10000 days
    select '2022-01-01' + interval (a.a + (10 * b.a) + (100 * c.a) + (1000 * d.a)) day as date_day
    from
        -- Units: 0-9
        (select 0 as a union all select 1 union all select 2 union all select 3
         union all select 4 union all select 5 union all select 6 union all select 7
         union all select 8 union all select 9) as a
    cross join
        -- Tens: 0-90
        (select 0 as a union all select 1 union all select 2 union all select 3
         union all select 4 union all select 5 union all select 6 union all select 7
         union all select 8 union all select 9) as b
    cross join
        -- Hundreds: 0-900
        (select 0 as a union all select 1 union all select 2 union all select 3
         union all select 4 union all select 5 union all select 6 union all select 7
         union all select 8 union all select 9) as c
    cross join
        -- Thousands: 0-9000
        (select 0 as a union all select 1 union all select 2 union all select 3) as d
    -- Filter to only include dates within our range
    where '2022-01-01' + interval (a.a + (10 * b.a) + (100 * c.a) + (1000 * d.a)) day <= '2025-12-31'
),

final as (
    select
        -- --------------------------------------------------------
        -- Surrogate Key
        -- Format: YYYYMMDD as integer e.g. 20220101
        -- Used to join fact tables to this dimension
        -- --------------------------------------------------------
        cast(date_format(date_day, '%Y%m%d') as unsigned)   as date_key,

        -- --------------------------------------------------------
        -- Full Date
        -- --------------------------------------------------------
        date_day                                             as full_date,

        -- --------------------------------------------------------
        -- Day attributes
        -- --------------------------------------------------------
        dayofmonth(date_day)                                 as day_of_month,

        -- day_of_week_number: 1=Sunday, 2=Monday ... 7=Saturday
        dayofweek(date_day)                                  as day_of_week_number,

        -- day_name: Monday, Tuesday, etc.
        dayname(date_day)                                    as day_name,

        -- --------------------------------------------------------
        -- Week attributes
        -- --------------------------------------------------------
        weekofyear(date_day)                                 as week_of_year,

        -- --------------------------------------------------------
        -- Month attributes
        -- --------------------------------------------------------
        month(date_day)                                      as month_number,

        -- month_name: January, February, etc.
        monthname(date_day)                                  as month_name,

        -- --------------------------------------------------------
        -- Quarter attributes
        -- --------------------------------------------------------
        quarter(date_day)                                    as quarter_number,

        -- quarter_name: Q1, Q2, Q3, Q4
        concat('Q', quarter(date_day))                       as quarter_name,

        -- --------------------------------------------------------
        -- Year
        -- --------------------------------------------------------
        year(date_day)                                       as year,

        -- --------------------------------------------------------
        -- Boolean flags (1=true, 0=false)
        -- --------------------------------------------------------

        -- is_weekend: 1 if Saturday or Sunday, 0 otherwise
        -- dayofweek: 1=Sunday, 7=Saturday
        case when dayofweek(date_day) in (1, 7) then 1 else 0 end as is_weekend,

        -- is_weekday: 1 if Monday to Friday, 0 otherwise
        case when dayofweek(date_day) not in (1, 7) then 1 else 0 end as is_weekday

    from date_spine
)

select * from final