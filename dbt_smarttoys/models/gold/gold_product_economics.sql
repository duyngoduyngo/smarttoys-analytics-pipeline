{{ config(materialized='table') }}


with items as (
    select * from {{ ref('silver_order_items_enriched') }}
),

by_product as (
    select
        product_id,
        product_name,
        count(*)                                  as items_sold,
        sum(case when is_refunded then 1 else 0 end) as refunded_items,
        sum(price_usd)                            as gross_revenue_usd,
        sum(cogs_usd)                             as total_cogs_usd,
        sum(refund_amount_usd)                    as total_refund_usd,
        sum(net_profit_usd)                       as net_profit_usd
    from items
    group by 1, 2
)

select
    *,
    round(net_profit_usd / gross_revenue_usd * 100, 2)        as net_margin_pct,
    round(refunded_items * 100.0 / items_sold, 2)             as refund_rate_pct,
    round(total_refund_usd / net_profit_usd * 100, 2)         as refund_as_pct_of_profit,
    round(gross_revenue_usd * 100.0
          / sum(gross_revenue_usd) over (), 2)                as revenue_share_pct
from by_product
order by gross_revenue_usd desc