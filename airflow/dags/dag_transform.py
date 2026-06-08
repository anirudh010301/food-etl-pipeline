# ============================================================
# DAG: dag_transform
# Purpose: Runs all dbt models layer by layer
# Schedule: Daily at 1am — runs after dag_extract completes
# Tasks:
#   1. dbt_staging      — runs staging models
#   2. dbt_ods          — runs ODS models
#   3. dbt_dwh          — runs DWH dimension + fact models
#   4. dbt_marts        — runs data mart models
# ============================================================

from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

# ============================================================
# Default arguments
# ============================================================
default_args = {
    'owner': 'food_etl',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    'email_on_failure': False,
    'email_on_retry': False,
}

# ============================================================
# dbt project path inside Airflow container
# ============================================================
DBT_PROJECT_DIR = '/opt/airflow/dbt/food_etl'

# ============================================================
# DAG definition
# ============================================================
with DAG(
    dag_id='dag_transform',
    default_args=default_args,
    description='Runs all dbt models layer by layer',

    # Runs at 1am — 1 hour after dag_extract
    schedule_interval='0 1 * * *',

    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['transform', 'dbt', 'food_etl'],

) as dag:

    # ============================================================
    # Task 1: Run dbt staging models
    # Creates views on top of raw staging tables
    # ============================================================
    dbt_staging = BashOperator(
        task_id='dbt_staging',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --models staging',
    )

    # ============================================================
    # Task 2: Run dbt ODS models
    # Cleans, standardizes and translates data
    # ============================================================
    dbt_ods = BashOperator(
        task_id='dbt_ods',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --models ods',
    )

    # ============================================================
    # Task 3: Run dbt DWH models
    # Builds star schema — dimensions and facts
    # ============================================================
    dbt_dwh = BashOperator(
        task_id='dbt_dwh',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --models dwh',
    )

    # ============================================================
    # Task 4: Run dbt mart models
    # Builds aggregated data marts with window functions
    # ============================================================
    dbt_marts = BashOperator(
        task_id='dbt_marts',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt run --models marts',
    )

    # ============================================================
    # Task dependencies — strict layer by layer execution
    # Each layer depends on the previous layer completing
    # ============================================================
    dbt_staging >> dbt_ods >> dbt_dwh >> dbt_marts