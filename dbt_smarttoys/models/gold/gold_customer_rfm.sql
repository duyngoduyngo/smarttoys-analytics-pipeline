{{ config(materialized='table') }}


with snapshot as (
    select max(created_at) + interval 1 day as snapshot_date
    from {{ ref('bronze_orders') }}
),

base as (
    select
        o.user_id,
        datediff('day', max(o.created_at), (select snapshot_date from snapshot)) as recency_days,
        count(distinct o.order_id) as frequency,
        sum(o.price_usd)           as monetary_usd
    from {{ ref('bronze_orders') }} o
    group by 1
),

scored as (
    select
        *,
        -- Recency càng nhỏ càng tốt, nên đảo chiều điểm
        6 - ntile(5) over (order by recency_days)      as r_score,
        ntile(5) over (order by monetary_usd)          as m_score,
        -- Frequency lệch nặng, dùng ngưỡng thủ công thay vì ntile
        case
            when frequency >= 3 then 5
            when frequency = 2  then 3
            else 1
        end                                            as f_score
    from base
)

select
    user_id,
    recency_days,
    frequency,
    monetary_usd,
    r_score,
    f_score,
    m_score,
    r_score * 100 + f_score * 10 + m_score as rfm_score,
    case
        when f_score >= 3 and r_score >= 4 then 'Champions'
        when f_score >= 3 and r_score >= 2 then 'Loyal'
        when f_score >= 3                  then 'At Risk'
        when r_score >= 4 and m_score >= 4 then 'Promising'
        when r_score >= 4                  then 'New Customers'
        when r_score <= 2                  then 'Hibernating'
        else 'Others'
    end as rfm_segment
from scored