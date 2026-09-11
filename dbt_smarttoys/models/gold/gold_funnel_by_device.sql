{{ config(materialized='table') }}


with steps as (
    select * from {{ ref('silver_funnel_steps') }}
),

unpivoted as (
    select device_type, 1 as step_order, 'Landed'         as step_name, step_landed         as reached from steps
    union all
    select device_type, 2, 'Products',       step_products       from steps
    union all
    select device_type, 3, 'Product Detail', step_product_detail from steps
    union all
    select device_type, 4, 'Cart',           step_cart           from steps
    union all
    select device_type, 5, 'Shipping',       step_shipping       from steps
    union all
    select device_type, 6, 'Billing',        step_billing        from steps
    union all
    select device_type, 7, 'Thank you',      step_thankyou       from steps
),

counted as (
    select
        device_type,
        step_order,
        step_name,
        sum(case when reached then 1 else 0 end) as sessions
    from unpivoted
    group by 1, 2, 3
)

select
    device_type,
    step_order,
    step_name,
    sessions,
    lag(sessions) over (partition by device_type order by step_order) as prev_sessions,
    round(sessions * 100.0
          / lag(sessions) over (partition by device_type order by step_order), 2) as ctr_prev_pct,
    round(100 - sessions * 100.0
          / lag(sessions) over (partition by device_type order by step_order), 2) as dropoff_pct,
    round(sessions * 100.0
          / first_value(sessions) over (partition by device_type order by step_order), 2) as cr_total_pct
from counted
order by device_type, step_order