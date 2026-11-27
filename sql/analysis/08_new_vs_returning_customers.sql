-- 08. New vs. returning customers per month
with purchases as (
    select distinct f.customer_key, d.year_month
    from marts.fact_sales as f
    join marts.dim_date   as d on f.date_key = d.date_key
    where f.customer_key <> -1 and not f.is_cancellation
),
first_month as (
    select customer_key, min(year_month) as first_month
    from purchases
    group by customer_key
)
select
    p.year_month,
    count(*) filter (where p.year_month =  fm.first_month) as new_customers,
    count(*) filter (where p.year_month >  fm.first_month) as returning_customers,
    round(100.0 * count(*) filter (where p.year_month > fm.first_month) / count(*), 1) as returning_pct
from purchases   as p
join first_month as fm using (customer_key)
group by p.year_month
order by p.year_month;