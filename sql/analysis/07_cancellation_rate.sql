-- 07. Cancellation rate by country: cancelled value as % of gross sales (countries with 50+ orders)
select
    c.country_clean,
    count(distinct f.invoice_no) filter (where not f.is_cancellation)          as orders,
    round(sum(f.revenue) filter (where not f.is_cancellation))                 as gross_sales,
    round(-sum(f.revenue) filter (where f.is_cancellation))                    as cancelled_value,
    round(100.0 * -sum(f.revenue) filter (where f.is_cancellation)
          / sum(f.revenue) filter (where not f.is_cancellation), 1)            as cancel_rate_pct
from marts.fact_sales  as f
join marts.dim_country as c on f.country_key = c.country_key
group by c.country_clean
having count(distinct f.invoice_no) filter (where not f.is_cancellation) >= 50
order by cancel_rate_pct desc;