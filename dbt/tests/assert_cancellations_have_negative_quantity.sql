-- A singular test: dbt fails the test if this query returns any rows.
select *
from {{ ref('stg_online_retail') }}
where (is_cancellation and quantity >= 0)
   or (not is_cancellation and quantity <= 0)