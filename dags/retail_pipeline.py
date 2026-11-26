"""Retail warehouse pipeline: extract -> load -> dbt seed -> dbt run -> dbt test."""

from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT_DIR = "/opt/project"
PYTHON = "/opt/airflow/project-venv/bin/python"
DBT = f"cd {PROJECT_DIR}/dbt && /opt/airflow/project-venv/bin/dbt"

default_args = {
    "owner": "data-team",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="retail_pipeline",
    description="Load Online Retail II into Postgres and build the star schema with dbt",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["retail", "dbt"],
) as dag:

    extract = BashOperator(
        task_id="extract",
        bash_command=f"cd {PROJECT_DIR} && {PYTHON} -m src.data.extract",
    )

    load = BashOperator(
        task_id="load_raw",
        bash_command=f"cd {PROJECT_DIR} && {PYTHON} -m src.data.load_raw",
    )

    dbt_seed = BashOperator(task_id="dbt_seed", bash_command=f"{DBT} seed")
    dbt_run = BashOperator(task_id="dbt_run", bash_command=f"{DBT} run")
    dbt_test = BashOperator(task_id="dbt_test", bash_command=f"{DBT} test")

    extract >> load >> dbt_seed >> dbt_run >> dbt_test