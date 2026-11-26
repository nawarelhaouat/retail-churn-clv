-- Runs only the first time the Postgres volume is created.
-- Airflow keeps its own bookkeeping (DAG runs, task states) in a separate database.
CREATE DATABASE airflow;