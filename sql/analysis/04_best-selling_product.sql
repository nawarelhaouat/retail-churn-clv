-- 04. Best-selling product in each country (top 1 per group)
with product_country as (
    select
        c.country_clean,
        p.description,
        sum(f.revenue)                                            as net_revenue,
        row_number() over (partition by c.country_clean
                           order by sum(f.revenue) desc)          as rn
    from marts.fact_sales  as f
    join marts.dim_product as p on f.product_key = p.product_key
    join marts.dim_country as c on f.country_key = c.country_key
    where p.is_merchandise
    group by c.country_clean, p.description
)
select country_clean, description, round(net_revenue) as net_revenue
from product_country
where rn = 1
order by net_revenue desc
limit 10;