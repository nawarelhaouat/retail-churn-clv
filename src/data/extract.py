"""Extract step: download Online Retail II and save each Excel sheet as a CSV."""

import io
import logging
import zipfile

import pandas as pd
import requests

from src.config import DATASET_URL, EXCEL_FILENAME, RAW_DATA_DIR

log = logging.getLogger(__name__)


def download() -> None:
    """Download the zip file and unpack the .xlsx into data/raw/."""
    xlsx_path = RAW_DATA_DIR / EXCEL_FILENAME
    if xlsx_path.exists():
        log.info("Found %s, skipping download", xlsx_path)
        return

    RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
    log.info("Downloading %s", DATASET_URL)
    response = requests.get(DATASET_URL, timeout=300)
    response.raise_for_status()  # stop with an error if the download failed (e.g. 404)

    # The zip is in memory (response.content); io.BytesIO makes it look like a file
    with zipfile.ZipFile(io.BytesIO(response.content)) as zf:
        zf.extract(EXCEL_FILENAME, RAW_DATA_DIR)
    log.info("Saved %s", xlsx_path)


def convert_to_csv() -> None:
    """Write one CSV per Excel sheet, keeping every value as text."""
    xlsx_path = RAW_DATA_DIR / EXCEL_FILENAME
    log.info("Reading %s (takes 1-3 minutes)...", xlsx_path)

    # sheet_name=None -> read ALL sheets, returns {sheet name: DataFrame}
    # dtype=str      -> keep everything as text, don't let pandas guess types
    sheets = pd.read_excel(xlsx_path, sheet_name=None, dtype=str)

    for sheet_name, df in sheets.items():
        df["source_sheet"] = sheet_name  # remember where each row came from
        # "Year 2009-2010" -> "online_retail_2009_2010.csv"
        years = sheet_name.replace("Year", "").strip().replace("-", "_")
        out_path = RAW_DATA_DIR / f"online_retail_{years}.csv"
        df.to_csv(out_path, index=False, lineterminator="\n")
        log.info("Wrote %s rows from '%s' to %s", f"{len(df):,}", sheet_name, out_path.name)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    download()
    convert_to_csv()