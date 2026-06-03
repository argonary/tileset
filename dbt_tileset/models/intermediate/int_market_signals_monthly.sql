-- models/intermediate/int_market_signals_monthly.sql
-- Aligns all three FRED signals to a monthly grain.
-- Mortgage rates arrive weekly and must be averaged down to monthly
-- before they can be joined with housing starts and permits.
-- Materialized as ephemeral -- compiled as a CTE, never lands a table.
-- Grain: one row per month.

with mortgage_monthly as (

    -- Aggregate weekly rates down to monthly average
    -- This resolves the granularity mismatch between weekly and monthly sources
    select
        date_trunc('month', obs_date)       as signal_month,
        round(avg(rate_pct), 4)             as avg_mortgage_rate,
        count(*)                            as weeks_in_month

    from {{ ref('stg_mortgage_rates') }}
    group by date_trunc('month', obs_date)

),

housing as (

    select
        date_trunc('month', obs_date)       as signal_month,
        starts_thousands

    from {{ ref('stg_housing_starts') }}

),

permits as (

    select
        date_trunc('month', obs_date)       as signal_month,
        permits_issued

    from {{ ref('stg_building_permits') }}

),

joined as (

    select
        m.signal_month,
        m.avg_mortgage_rate,
        m.weeks_in_month,
        h.starts_thousands,
        p.permits_issued

    from mortgage_monthly   m
    left join housing       h on m.signal_month = h.signal_month
    left join permits       p on m.signal_month = p.signal_month

)

select * from joined