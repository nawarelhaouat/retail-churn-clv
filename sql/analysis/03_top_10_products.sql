-- 03. Top 10 products by net revenue (merchandise only), with rank
select
    rank() over (order by sum(f.revenue) desc)   as revenue_rank,
    p.stock_code,
    p.description,
    sum(f.quantity)                              as units_sold,
    round(sum(f.revenue))                        as net_revenue
from marts.fact_sales  as f
join marts.dim_product as p on f.product_key = p.product_key
where p.is_merchandise
group by p.stock_code, p.description
order by revenue_rank
limit 10;