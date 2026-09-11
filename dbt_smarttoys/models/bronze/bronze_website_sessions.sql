with source as (
    select * from {{ source('raw', 'website_sessions') }}
)

select
    website_session_id,
    cast(created_at as timestamp)                 as created_at,
    date_trunc('month', cast(created_at as date)) as session_month,
    user_id,
    is_repeat_session,
    -- Session không gắn UTM là traffic hợp lệ (truy cập trực tiếp/organic),
    -- không phải lỗi nhập liệu. Gán nhãn thay vì loại bỏ.
    coalesce(utm_source, 'direct/organic')        as utm_source,
    coalesce(utm_campaign, 'none')                as utm_campaign,
    coalesce(utm_content, 'none')                 as utm_content,
    coalesce(http_referer, 'direct')              as http_referer,
    lower(trim(device_type))                      as device_type
from source