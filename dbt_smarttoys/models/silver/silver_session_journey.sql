{{ config(materialized='view') }}


with sessions as (
    select * from {{ ref('bronze_website_sessions') }}
),

-- Landing page = trang đầu tiên trong phiên.
landing as (
    select
        website_session_id,
        pageview_url as landing_page
    from (
        select
            website_session_id,
            pageview_url,
            row_number() over (
                partition by website_session_id
                order by created_at, website_pageview_id
            ) as rn
        from {{ ref('bronze_website_pageviews') }}
    )
    where rn = 1
),


orders as (
    select
        website_session_id,
        count(*)               as order_count,
        min(order_id)          as first_order_id,
        sum(price_usd)         as revenue_usd,
        sum(items_purchased)   as items_purchased,
        min(primary_product_id) as primary_product_id
    from {{ ref('bronze_orders') }}
    group by 1
)

select
    s.website_session_id,
    s.user_id,
    s.created_at,
    s.session_month,
    s.utm_source,
    s.device_type,
    s.is_repeat_session,
    l.landing_page,
    coalesce(o.order_count, 0)      as order_count,
    o.first_order_id,
    coalesce(o.revenue_usd, 0)      as revenue_usd,
    coalesce(o.items_purchased, 0)  as items_purchased,
    o.primary_product_id,
    coalesce(p.product_name, 'None (Drop-off)') as product_name,
    o.website_session_id is not null as is_converted
from sessions s
left join landing  l on s.website_session_id = l.website_session_id
left join orders   o on s.website_session_id = o.website_session_id
left join {{ ref('bronze_products') }} p on o.primary_product_id = p.product_id