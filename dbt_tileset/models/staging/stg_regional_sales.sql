-- models/staging/stg_regional_sales.sql
-- Cleans and type-casts the regional sales seed table.
-- Grain: one row per region per month per product line.

with source as (

    select * from {{ ref('regional_sales') }}

),

cleaned as (

    select
        region,
        to_date(sale_month, 'yyyy-MM')      as sale_month,
        product_line,
        cast(units_sold as int)             as units_sold,
        cast(revenue as double)             as revenue,
        round(
            cast(revenue as double) 
            / nullif(cast(units_sold as int), 0)
        , 2)                                as revenue_per_unit

    from source

    where region is not null
      and sale_month is not null

)

select * from cleaned