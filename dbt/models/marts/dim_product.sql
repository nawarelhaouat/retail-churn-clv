-- One row per stock code. A code can have several descriptions (typos, renames),
-- so we keep the one used most often.

with products as (

    select
        stock_code,
        mode() within group (order by description)  as description
    from {{ ref('stg_online_retail') }}
    where description is not null
    group by stock_code

),

all_codes as (

    -- Codes whose description is always missing still need a row.
    select distinct stock_code from {{ ref('stg_online_retail') }}

)

select
    row_number() over (order by c.stock_code)::integer   as product_key,
    c.stock_code,
    coalesce(p.description, 'UNKNOWN')                   as description,
    coalesce(nm.category, 'merchandise')                 as product_category,
    nm.stock_code is null                                as is_merchandise
from all_codes as c
left join products as p
    on c.stock_code = p.stock_code
left join {{ ref('non_merchandise_codes') }} as nm
    on c.stock_code = nm.stock_code