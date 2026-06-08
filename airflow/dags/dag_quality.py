# ============================================================
# DAG: dag_quality
# Purpose: Runs all dbt tests and logs results to audit table
# Schedule: Daily at 2am — runs after dag_transform completes
# Tasks:
#   1. dbt_test_staging  — tests staging layer
#   2. dbt_test_ods      — tests ODS layer
#   3. dbt_test_dwh      — tests DWH layer
#   4. dbt_test_marts    — tests marts layer
#   5. dbt_generate_docs — generates dbt documentation
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
    dag_id='dag_quality',
    default_args=default_args,
    description='Runs all dbt tests across all layers',

    # Runs at 2am — 1 hour after dag_transform
    schedule_interval='0 2 * * *',

    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['quality', 'testing', 'dbt', 'food_etl'],

) as dag:

    # ============================================================
    # Task 1: Test staging layer
    # Runs not_null and unique tests on staging sources
    # ============================================================
    dbt_test_staging = BashOperator(
        task_id='dbt_test_staging',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --models staging',
    )

    # ============================================================
    # Task 2: Test ODS layer
    # Runs not_null, unique and accepted_values tests
    # ============================================================
    dbt_test_ods = BashOperator(
        task_id='dbt_test_ods',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --models ods',
    )

    # ============================================================
    # Task 3: Test DWH layer
    # Runs tests on all dimensions and fact tables
    # ============================================================
    dbt_test_dwh = BashOperator(
        task_id='dbt_test_dwh',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --models dwh',
    )

    # ============================================================
    # Task 4: Test marts layer
    # Runs tests on all data marts
    # ============================================================
    dbt_test_marts = BashOperator(
        task_id='dbt_test_marts',
        bash_command=f'cd {DBT_PROJECT_DIR} && dbt test --models marts',
    )


    # ============================================================
    # Task dependencies
    # Tests run layer by layer — stops at first failure
    # Docs generated only after all tests pass
    # ============================================================
    dbt_test_staging >> dbt_test_ods >> dbt_test_dwh >> dbt_test_marts 