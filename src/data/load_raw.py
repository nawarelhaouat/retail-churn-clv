"""Load step: copy the CSVs into PostgreSQL (raw.online_retail), unchanged."""

import logging

import psycopg

from src.config import RAW_DATA_DIR, pg_conninfo

log = logging.getLogger(__name__)

# Every column is TEXT: the raw layer stores the data exactly as received.
DDL = """
CREATE SCHEMA IF NOT EXISTS raw;
CREATE TABLE IF NOT EXISTS raw.online_retail (
    invoice       TEXT,
    stock_code    TEXT,
    description   TEXT,
    quantity      TEXT,
    invoice_date  TEXT,
    price         TEXT,
    customer_id   TEXT,
    country       TEXT,
    source_sheet  TEXT,
    loaded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
"""

COLUMNS = "invoice, stock_code, description, quantity, invoice_date, price, customer_id, country, source_sheet"


def load() -> None:
    csv_files = sorted(RAW_DATA_DIR.glob("online_retail_*.csv"))
    if not csv_files:
        raise FileNotFoundError("No CSV files found. Run `python -m src.data.extract` first.")

    # The `with` block = one transaction: COMMIT if everything works, ROLLBACK on any error
    with psycopg.connect(pg_conninfo()) as conn:
        with conn.cursor() as cur:
            cur.execute(DDL)
            cur.execute("TRUNCATE raw.online_retail")  # empty the table: full reload

            for path in csv_files:
                sql = f"COPY raw.online_retail ({COLUMNS}) FROM STDIN WITH (FORMAT csv, HEADER true)"
                with open(path, "rb") as f, cur.copy(sql) as copy:
                    while chunk := f.read(1024 * 1024):  # send the file in 1 MB pieces
                        copy.write(chunk)
                log.info("Loaded %s", path.name)

            cur.execute("SELECT count(*) FROM raw.online_retail")
            log.info("raw.online_retail now has %s rows", f"{cur.fetchone()[0]:,}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    load()