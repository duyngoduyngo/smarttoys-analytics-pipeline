{{ config(materialized='view') }}

with items as (
    select * from {{ ref('bronze_order_items') }}
),

products as (
    select product_id, product_name from {{ ref('bronze_products') }}
),


refunds as (
    select
        order_item_id,
        sum(refund_amount_usd) as refund_amount_usd,
        count(*)               as refund_count
    from {{ ref('bronze_order_item_refunds') }}
    group by 1
)

select
    i.order_item_id,
    i.order_id,
    i.product_id,
    p.product_name,
    i.created_at,
    date_trunc('month', cast(i.created_at as date)) as item_month,
    extract(month from i.created_at)                as month_of_year,
    i.is_primary_item,
    i.price_usd,
    i.cogs_usd,
    coalesce(r.refund_amount_usd, 0)                as refund_amount_usd,
    coalesce(r.refund_count, 0)                     as refund_count,
    r.order_item_id is not null                     as is_refunded,
    i.price_usd - i.cogs_usd - coalesce(r.refund_amount_usd, 0) as net_profit_usd
from items i
left join products p on i.product_id = p.product_id
left join refunds  r on i.order_item_id = r.order_item_id