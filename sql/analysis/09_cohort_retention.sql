-- 09. Cohort retention: of customers who first bought in month M, what % bought again in M+1, M+3, M+6?
with purchases as (
    select distinct
        f.customer_key,
        date_trunc('month', f.invoice_ts)::date as month
    from marts.fact_sales as f
    where f.customer_key <> -1 and not f.is_cancellation
),
cohorts as (
    select customer_key, min(month) as cohort_month
    from purchases
    group by customer_key
),
activity as (
    select
        c.cohort_month,
        p.customer_key,
        (extract(year from age(p.month, c.cohort_month)) * 12
         + extract(month from age(p.month, c.cohort_month)))::int as months_since_first
    from purchases as p
    join cohorts   as c using (customer_key)
)
select
    to_char(cohort_month, 'YYYY-MM')                                          as cohort,
    count(distinct customer_key) filter (where months_since_first = 0)       as cohort_size,
    round(100.0 * count(distinct customer_key) filter (where months_since_first = 1)
          / count(distinct customer_key) filter (where months_since_first = 0), 1) as m1_pct,
    round(100.0 * count(distinct customer_key) filter (where months_since_first = 3)
          / count(distinct customer_key) filter (where months_since_first = 0), 1) as m3_pct,
    round(100.0 * count(distinct customer_key) filter (where months_since_first = 6)
          / count(distinct customer_key) filter (where months_since_first = 0), 1) as m6_pct
from activity
where cohort_month <= date '2011-05-01'   -- later cohorts can't be observed 6 months ahead
group by cohort_month
order by cohort_month;