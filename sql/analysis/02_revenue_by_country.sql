-- 02. Revenue by country and its share of the total (top 10)
select
    c.country_clean,
    round(sum(f.revenue))                                              as net_revenue,
    round(100.0 * sum(f.revenue) / sum(sum(f.revenue)) over (), 2)     as pct_of_total,
    count(distinct f.customer_key) filter (where f.customer_key <> -1) as customers
from marts.fact_sales  as f
join marts.dim_country as c on f.country_key = c.country_key
group by c.country_clean
order by net_revenue desc
limit 10;