-- One row per country, with readable names for the dashboard.

with countries as (

    select distinct country as country_name
    from {{ ref('stg_online_retail') }}

)

select
    row_number() over (order by country_name)::integer   as country_key,
    country_name,
    case country_name
        when 'EIRE'               then 'Ireland'
        when 'RSA'                then 'South Africa'
        when 'USA'                then 'United States'
        when 'Korea'              then 'South Korea'
        when 'Unspecified'        then 'Unknown'
        else country_name
    end                                                  as country_clean,
    country_name = 'United Kingdom'                      as is_uk
from countries