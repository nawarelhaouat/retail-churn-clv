"""Read data from the PostgreSQL warehouse (the dbt marts) into pandas."""

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from src.config import PG


def get_engine() -> Engine:
    """SQLAlchemy engine for the warehouse (pandas works best with SQLAlchemy)."""
    url = (
        f"postgresql+psycopg://{PG['user']}:{PG['password']}"
        f"@{PG['host']}:{PG['port']}/{PG['dbname']}"
    )
    return create_engine(url)


ORDERS_SQL = """
select
    c.customer_id,
    f.invoice_no,
    min(f.invoice_ts)      as order_ts,
    sum(f.revenue)         as order_value,
    sum(f.quantity)        as items,
    count(*)               as lines
from marts.fact_sales   as f
join marts.dim_customer as c on f.customer_key = c.customer_key
where f.customer_key <> -1        -- guests cannot be tracked over time
  and not f.is_cancellation       -- a cancellation is not a purchase
group by c.customer_id, f.invoice_no
"""


def load_orders() -> pd.DataFrame:
    """One row per order (invoice) of a known customer, sorted by customer and time."""
    orders = pd.read_sql(ORDERS_SQL, get_engine(), parse_dates=["order_ts"])
    return orders.sort_values(["customer_id", "order_ts"]).reset_index(drop=True)