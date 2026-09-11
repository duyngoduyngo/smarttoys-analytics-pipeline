{{ config(materialized='table') }}


with orders as (
    select
        user_id,
        order_id,
        date_trunc('month', cast(created_at as date)) as order_month,
        price_usd
    from {{ ref('bronze_orders') }}
),

with_cohort as (
    select
        *,
        min(order_month) over (partition by user_id) as cohort_month
    from orders
),

with_period as (
    select
        *,
        datediff('month', cohort_month, order_month) as period_index
    from with_cohort
),

counts as (
    select
        cohort_month,
        period_index,
        count(distinct user_id) as active_users
    from with_period
    group by 1, 2
),

cohort_size as (
    select cohort_month, active_users as size
    from counts
    where period_index = 0
)

select
    c.cohort_month,
    c.period_index,
    c.active_users,
    s.size                                            as cohort_size,
    round(c.active_users * 100.0 / s.size, 2)         as retention_pct
from counts c
join cohort_size s on c.cohort_month = s.cohort_month
order by c.cohort_month, c.period_index