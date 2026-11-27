-- 06. Average basket: revenue and items per order, by year
with orders as (
    select
        f.invoice_no,
        min(d.year)            as year,
        sum(f.revenue)         as order_value,
        sum(f.quantity)        as items,
        count(*)               as lines
    from marts.fact_sales as f
    join marts.dim_date   as d on f.date_key = d.date_key
    where not f.is_cancellation
    group by f.invoice_no
)
select
    year,
    count(*)                    as orders,
    round(avg(order_value), 2)  as avg_order_value,
    round(percentile_cont(0.5) within group (order by order_value)::numeric, 2) as median_order_value,
    round(avg(items), 1)        as avg_items,
    round(avg(lines), 1)        as avg_distinct_lines
from orders
group by year
order by year;