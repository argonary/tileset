-- models/staging/stg_housing_starts.sql
-- Cleans and type-casts the raw housing starts Bronze table.
-- Grain: one row per month.

with source as (

    select * from {{ source('tileset_bronze', 'raw_houst') }}

),

cleaned as (

    select
        series_id,
        obs_date,
        cast(starts_thousands as double)    as starts_thousands,
        _ingested_at

    from source

    where obs_date is not null
      and starts_thousands is not null

)

select * from cleaned
