-- Tiền hoàn không được vượt quá giá bán của chính dòng hàng đó.
-- Nếu vượt, hoặc dữ liệu nguồn sai, hoặc logic gộp refund bị fan-out.

select
    order_item_id,
    price_usd,
    refund_amount_usd
from {{ ref('silver_order_items_enriched') }}
where refund_amount_usd > price_usd