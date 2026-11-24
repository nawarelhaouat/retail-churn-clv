-- Staging: one clean row per invoice line.
-- Rules: cast types, remove exact duplicates, drop non-sales rows, add flags.

with source as (

    select * from {{ source('raw', 'online_retail') }}

),

typed as (

    select
        trim(invoice)                               as invoice_no,
        upper(trim(stock_code))                     as stock_code,
        nullif(trim(description), '')               as description,
        quantity::integer                           as quantity,
        price::numeric(12, 2)                       as unit_price,
        invoice_date::timestamp                     as invoice_ts,
        nullif(trim(customer_id), '')::integer      as customer_id,
        trim(country)                               as country,
        source_sheet
    from source

),

deduplicated as (

    -- Rule 1: exact duplicate lines are kept once.
    -- Covers the 1-9 Dec 2010 overlap between the sheets and double-scanned lines.
    select
        *,
        row_number() over (
            partition by invoice_no, stock_code, description, quantity,
                         unit_price, invoice_ts, customer_id, country
            order by source_sheet
        ) as row_num
    from typed

)

select
    md5(concat_ws('|', invoice_no, stock_code, description, quantity,
                  unit_price, invoice_ts, customer_id, country))   as sales_line_id,
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    quantity * unit_price                                           as revenue,
    invoice_ts,
    customer_id,
    country,
    invoice_no like 'C%'                                            as is_cancellation,
    customer_id is null                                             as is_guest
from deduplicated
where row_num = 1
  and invoice_no not like 'A%'                                      -- Rule 2: bad-debt adjustments
  and unit_price > 0                                                -- Rule 3: free items / write-offs
  and ((invoice_no like 'C%' and quantity < 0) or (invoice_no not like 'C%' and quantity > 0))   -- Rule 4: stock write-offs