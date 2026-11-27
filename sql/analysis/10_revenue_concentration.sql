-- 10. Revenue concentration (Pareto): what share of revenue comes from the top X% of customers?
with customer_revenue as (
    select customer_key, sum(revenue) as revenue
    from marts.fact_sales
    where customer_key <> -1
    group by customer_key
),
ranked as (
    select
        revenue,
        ntile(10) over (order by revenue desc) as decile
    from customer_revenue
)
select
    decile,
    count(*)                                                   as customers,
    round(sum(revenue))                                        as revenue,
    round(100.0 * sum(revenue) / sum(sum(revenue)) over (), 1) as pct_of_revenue,
    round(100.0 * sum(sum(revenue)) over (order by decile)
          / sum(sum(revenue)) over (), 1)                      as cumulative_pct
from ranked
group by decile
order by decile;