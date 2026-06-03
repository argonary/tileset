-- models/staging/stg_building_permits.sql
-- Cleans and type-casts the raw building permits Bronze table.
-- Grain: one row per month.

with source as (

    select * from {{ source('tileset_bronze', 'raw_permit') }}

),

cleaned as (

    select
        series_id,
        obs_date,
        cast(permits_issued as double)    as permits_issued,
        _ingested_at

    from source

    where obs_date is not null
      and permits_issued is not null

)

select * from cleaned