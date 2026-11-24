"""Central configuration: file paths and database connection settings."""

import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()  # reads .env and puts its values into os.environ

# Path(__file__) = this file; .parents[1] = two levels up = the project root
PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

DATASET_URL = "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip"
EXCEL_FILENAME = "online_retail_II.xlsx"

# os.getenv("NAME", default) -> the value from .env, or the default if it's missing
PG = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": os.getenv("PGPORT", "5432"),
    "dbname": os.getenv("PGDATABASE", "retail"),
    "user": os.getenv("PGUSER", "retail"),
    "password": os.getenv("PGPASSWORD", "retail"),
}


def pg_conninfo() -> str:
    """Build a connection string like 'host=localhost port=5432 dbname=retail ...'."""
    return " ".join(f"{key}={value}" for key, value in PG.items())