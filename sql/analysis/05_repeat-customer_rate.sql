-- 05. Repeat-customer rate: share of known customers with 2+ orders
with orders_per_customer as (
    select customer_key, count(distinct invoice_no) as n_orders
    from marts.fact_sales
    where customer_key <> -1
      and not is_cancellation
    group by customer_key
)
select
    count(*)                                                  as customers,
    count(*) filter (where n_orders >= 2)                     as repeat_customers,
    round(100.0 * count(*) filter (where n_orders >= 2) / count(*), 1) as repeat_rate_pct,
    percentile_cont(0.5) within group (order by n_orders)     as median_orders
from orders_per_customer;