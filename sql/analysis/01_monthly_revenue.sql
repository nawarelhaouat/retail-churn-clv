-- 01. Monthly net revenue, orders and active customers, with month-over-month growth
with monthly as (
    select
        d.year_month,
        sum(f.revenue)                                                as net_revenue,
        count(distinct f.invoice_no) filter (where not f.is_cancellation) as orders,
        count(distinct f.customer_key) filter (where f.customer_key <> -1
                                                 and not f.is_cancellation) as active_customers
    from marts.fact_sales as f
    join marts.dim_date   as d on f.date_key = d.date_key
    group by d.year_month
)
select
    year_month,
    round(net_revenue)                                             as net_revenue,
    orders,
    active_customers,
    round(100.0 * (net_revenue - lag(net_revenue) over (order by year_month))
          / lag(net_revenue) over (order by year_month), 1)        as mom_growth_pct
from monthly
order by year_month;