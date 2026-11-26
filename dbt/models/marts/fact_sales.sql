-- One row per invoice line (the grain). Measures + foreign keys to the dimensions.

with sales as (

    select * from {{ ref('stg_online_retail') }}

)

select
    s.sales_line_id                                     as sales_key,
    s.invoice_no,
    to_char(s.invoice_ts, 'YYYYMMDD')::integer          as date_key,
    coalesce(c.customer_key, -1)                        as customer_key,
    p.product_key,
    co.country_key,
    s.invoice_ts,
    s.quantity,
    s.unit_price,
    s.revenue,
    s.is_cancellation
from sales as s
left join {{ ref('dim_customer') }} as c
    on s.customer_id = c.customer_id
left join {{ ref('dim_product') }} as p
    on s.stock_code = p.stock_code
left join {{ ref('dim_country') }} as co
    on s.country = co.country_name