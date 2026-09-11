-- Số dòng trong silver_session_journey phải bằng đúng số phiên truy cập.
-- Khi phân tích bằng pandas, lỗi này từng phải chặn bằng assert thủ công;
-- ở đây nó chạy tự động mỗi lần build.

with counts as (
    select
        (select count(*) from {{ ref('silver_session_journey') }})  as journey_rows,
        (select count(*) from {{ ref('bronze_website_sessions') }}) as session_rows
)

select * from counts
where journey_rows != session_rows