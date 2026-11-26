-- One row per calendar day between the first and last sale (a "date spine").

with bounds as (

    select
        min(invoice_ts)::date as start_date,
        max(invoice_ts)::date as end_date
    from {{ ref('stg_online_retail') }}

),

days as (

    select generate_series(start_date, end_date, interval '1 day')::date as full_date
    from bounds

)

select
    to_char(full_date, 'YYYYMMDD')::integer     as date_key,
    full_date,
    extract(year from full_date)::integer       as year,
    extract(quarter from full_date)::integer    as quarter,
    extract(month from full_date)::integer      as month,
    to_char(full_date, 'FMMonth')               as month_name,
    to_char(full_date, 'YYYY-MM')               as year_month,
    extract(week from full_date)::integer       as iso_week,
    extract(isodow from full_date)::integer     as day_of_week,   -- 1 = Monday
    to_char(full_date, 'FMDay')                 as day_name,
    extract(isodow from full_date) in (6, 7)    as is_weekend
from days