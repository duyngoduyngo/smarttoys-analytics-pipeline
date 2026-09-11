{{ config(materialized='view') }}

with pageviews as (
    select distinct
        website_session_id,
        pageview_url
    from {{ ref('bronze_website_pageviews') }}
),

flags as (
    select
        website_session_id,
        max(case when pageview_url = '/products' then 1 else 0 end) as hit_products,
        max(case when pageview_url in (
                '/the-original-mr-fuzzy',
                '/the-forever-love-bear',
                '/the-birthday-sugar-panda',
                '/the-hudson-river-mini-bear'
            ) then 1 else 0 end) as hit_product_detail,
        max(case when pageview_url = '/cart' then 1 else 0 end) as hit_cart,
        max(case when pageview_url = '/shipping' then 1 else 0 end) as hit_shipping,
        max(case when pageview_url in ('/billing', '/billing-2') then 1 else 0 end) as hit_billing,
        max(case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end) as hit_thankyou
    from pageviews
    group by 1
)

select
    s.website_session_id,
    s.device_type,
    s.utm_source,
    s.session_month,
    true                                as step_landed,
    coalesce(f.hit_products, 0) = 1      as step_products,
    coalesce(f.hit_product_detail, 0) = 1 as step_product_detail,
    coalesce(f.hit_cart, 0) = 1          as step_cart,
    coalesce(f.hit_shipping, 0) = 1      as step_shipping,
    coalesce(f.hit_billing, 0) = 1       as step_billing,
    coalesce(f.hit_thankyou, 0) = 1      as step_thankyou
from {{ ref('bronze_website_sessions') }} s
left join flags f on s.website_session_id = f.website_session_id