select
    website_pageview_id,
    cast(created_at as timestamp) as created_at,
    website_session_id,
    pageview_url
from {{ source('raw', 'website_pageviews') }}