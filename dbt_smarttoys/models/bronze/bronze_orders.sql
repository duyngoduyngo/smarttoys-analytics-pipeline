with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id,
    cast(created_at as timestamp)              as created_at,
    date_trunc('month', cast(created_at as date)) as order_month,
    website_session_id,
    user_id,
    primary_product_id,
    items_purchased,
    price_usd,
    cogs_usd,
    price_usd - cogs_usd                        as gross_profit_usd,
    case when items_purchased > 1
         then 'Cross-sell' else 'Single' end    as order_type
from source