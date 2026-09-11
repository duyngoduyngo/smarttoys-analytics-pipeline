select
    product_id,
    cast(created_at as timestamp) as created_at,
    product_name
from {{ source('raw', 'products') }}