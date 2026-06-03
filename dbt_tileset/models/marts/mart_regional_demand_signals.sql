-- models/marts/mart_regional_demand_signals.sql
-- Regional demand intelligence table.
-- Joins monthly macro signals to regional sales data.
-- Flags regions where construction demand is outpacing sales coverage.
-- Grain: one row per region per month.
-- Materialized as a Delta table for fast BI queries.

with signals as (

    select * from {{ ref('int_market_signals_monthly') }}

),

sales as (

    select
        region,
        date_trunc('month', sale_month)     as sale_month,
        sum(units_sold)                     as units_sold,
        sum(revenue)                        as revenue

    from {{ ref('stg_regional_sales') }}
    group by region, date_trunc('month', sale_month)

),

joined as (

    select
        s.region,
        s.sale_month                        as signal_month,
        sig.avg_mortgage_rate,
        sig.starts_thousands,
        sig.permits_issued,
        s.units_sold,
        s.revenue

    from sales              s
    left join signals       sig on s.sale_month = sig.signal_month

),

with_permit_growth as (

    select
        signal_month,
        permits_issued,
        round(
            (permits_issued - lag(permits_issued) over (
                order by signal_month
            ))
            / nullif(lag(permits_issued) over (
                order by signal_month
            ), 0)
        , 4)                            as permits_mom_growth

    from (
        select distinct signal_month, permits_issued
        from joined
    )

),

with_growth as (

    select
        j.*,
        p.permits_mom_growth,

        -- Month-over-month revenue growth per region
        round(
            (j.revenue - lag(j.revenue) over (
                partition by j.region
                order by j.signal_month
            ))
            / nullif(lag(j.revenue) over (
                partition by j.region
                order by j.signal_month
            ), 0)
        , 4)                            as revenue_mom_growth

    from joined j
    left join with_permit_growth p on j.signal_month = p.signal_month

),
final as (

    select
        *,
        case
            when permits_mom_growth > revenue_mom_growth + 0.05
                then 'Accelerating'
            when permits_mom_growth < revenue_mom_growth - 0.05
                then 'Decelerating'
            else 'Flat'
        end                                 as demand_gap_flag

    from with_growth

)

select * from final