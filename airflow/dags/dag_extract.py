# ============================================================
# DAG: dag_extract
# Purpose: Downloads Kaggle data and loads into staging layer
# Schedule: Daily at midnight
# Tasks:
#   1. download_data    — downloads Kaggle dataset
#   2. verify_files     — verifies downloaded files exist
#   3. load_staging     — loads data into MySQL staging tables
# ============================================================

from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

# ============================================================
# Default arguments applied to all tasks in this DAG
# ============================================================
default_args = {
    # DAG owner
    'owner': 'food_etl',

    # If a run fails don't automatically retry
    'retries': 1,

    # Wait 5 minutes before retrying a failed task
    'retry_delay': timedelta(minutes=5),

    # Email on failure — disabled for now
    'email_on_failure': False,
    'email_on_retry': False,
}

# ============================================================
# DAG definition
# ============================================================
with DAG(
    # Unique DAG ID — shows in Airflow UI
    dag_id='dag_extract',

    # Apply default args defined above
    default_args=default_args,

    # Human readable description
    description='Downloads Kaggle data and loads into staging',

    # Run daily at midnight
    schedule_interval='0 0 * * *',

    # Start date — use a past date so Airflow doesn't backfill
    start_date=datetime(2024, 1, 1),

    # Don't run for all missed dates since start_date
    catchup=False,

    # Tags for filtering in Airflow UI
    tags=['extract', 'staging', 'food_etl'],

) as dag:

    # ============================================================
    # Task 1: Download Kaggle dataset
    # Uses BashOperator — more reliable than PythonOperator
    # Explicitly uses our Python environment
    # ============================================================
    download_data = BashOperator(
        task_id='download_data',
        bash_command='cd /opt/airflow && python extract/scripts/extract_kaggle.py',
    )

    # ============================================================
    # Task 2: Verify downloaded files exist
    # Simple bash check — fails if files missing
    # ============================================================
    verify_files = BashOperator(
        task_id='verify_files',
        bash_command='ls /opt/airflow/data/raw/ && echo "Files verified"',
    )

    # ============================================================
    # Task 3: Load data into MySQL staging tables
    # ============================================================
    load_staging = BashOperator(
        task_id='load_staging',
        bash_command='cd /opt/airflow && python extract/scripts/load_staging.py',
    )

    # ============================================================
    # Task dependencies — defines execution order
    # download_data must complete before verify_files
    # verify_files must complete before load_staging
    # ============================================================
    download_data >> verify_files >> load_staging