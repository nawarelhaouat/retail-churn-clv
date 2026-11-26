-- One row per known customer, plus one "unknown customer" row (key -1) for guests.

with sales as (

    select * from {{ ref('stg_online_retail') }}
    where customer_id is not null

),

customers as (

    select
        customer_id,
        mode() within group (order by country)             as primary_country,
        min(invoice_ts)::date                              as first_purchase_date,
        max(invoice_ts) filter (where not is_cancellation)::date as last_purchase_date
    from sales
    group by customer_id

)

select
    row_number() over (order by customer_id)::integer   as customer_key,
    customer_id,
    primary_country,
    first_purchase_date,
    last_purchase_date
from customers

union all

select
    -1              as customer_key,
    null            as customer_id,
    null            as primary_country,
    null            as first_purchase_date,
    null            as last_purchase_date