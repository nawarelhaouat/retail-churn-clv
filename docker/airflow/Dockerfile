FROM apache/airflow:3.3.2-python3.12

# Our project's packages go into their own virtual environment, so they can never
# conflict with the packages Airflow itself depends on.
COPY requirements.txt /tmp/requirements.txt
RUN python -m venv /opt/airflow/project-venv \
 && /opt/airflow/project-venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt