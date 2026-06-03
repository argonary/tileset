-- models/staging/stg_mortgage_rates.sql
-- Cleans and type-casts the raw mortgage rates Bronze table.
-- Grain: one row per week.

with source as (

    select * from {{ source('tileset_bronze', 'raw_mortgage30us') }}

),

cleaned as (

    select
        series_id,
        obs_date,
        cast(rate_pct as double)     as rate_pct,
        _ingested_at

    from source

    where obs_date is not null
      and rate_pct is not null

)

select * from cleaned