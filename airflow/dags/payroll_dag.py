import os
from datetime import datetime

from scripts.extract import (
    _get_google_drive_file_content,
    _get_google_drive_file_list,
    _ingest_file_to_s3,
)
from scripts.process import S3CsvFileProcessor

from airflow.decorators import dag, task
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.providers.slack.notifications.slack import SlackNotifier

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_DRIVE_FOLDER_ID = os.getenv("GOOGLE_DRIVE_FOLDER_ID")

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_ENDPOINT = os.getenv("AWS_ENDPOINT")

DBT_USER = os.getenv("DBT_USER")
DBT_ROLE = os.getenv("DBT_ROLE")
DBT_PASSWORD = os.getenv("DBT_PASSWORD")

SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WAREHOUSE")
SNOWFLAKE_DATABASE = os.getenv("SNOWFLAKE_DATABASE")
SNOWFLAKE_SCHEMA = os.getenv("SNOWFLAKE_SCHEMA")
SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.getenv("SNOWFLAKE_PASSWORD")
SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE")


@dag(
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["payroll"],
    on_failure_callback=SlackNotifier(
        slack_conn_id="slack",
        channel="payroll",
        text="Payroll DAG failed",
    ),
    on_success_callback=SlackNotifier(
        slack_conn_id="slack",
        channel="payroll",
        text="Payroll DAG succeeded",
    ),
)
def payroll_dag():
    @task
    def get_google_drive_file_list():
        gd_file_list = _get_google_drive_file_list(
            folder_id=GOOGLE_DRIVE_FOLDER_ID, api_key=GOOGLE_API_KEY
        )
        return gd_file_list

    @task
    def ingest_file(gd_file):
        gd_file_content = _get_google_drive_file_content(
            file_id=gd_file["id"], api_key=GOOGLE_API_KEY
        )
        s3_raw_file_url = _ingest_file_to_s3(
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            object_name=gd_file["name"],
            data=gd_file_content,
        )
        return s3_raw_file_url

    @task
    def process_file(s3_raw_file_url):
        processor = S3CsvFileProcessor(
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        )
        s3_processed_file_url = processor._process_file(s3_raw_file_url)
        return s3_processed_file_url

    @task
    def aggregate_processed_files(**kwargs):
        ti = kwargs["task_instance"]
        aggregated_file_list = []
        i = 0
        while True:
            output = ti.xcom_pull(task_ids="process_file", map_indexes=i)
            if output is None:
                break
            aggregated_file_list.append(output)
            i += 1
        return aggregated_file_list

    load_to_snowflake = DockerOperator(
        task_id="load_to_snowflake",
        image="spark-app",
        api_version="auto",
        auto_remove="force",
        docker_url="tcp://docker-proxy:2375",
        network_mode="container:spark-master",
        tty=True,
        xcom_all=False,
        mount_tmp_dir=False,
        environment={
            "AWS_ACCESS_KEY_ID": AWS_ACCESS_KEY_ID,
            "AWS_SECRET_ACCESS_KEY": AWS_SECRET_ACCESS_KEY,
            "AWS_ENDPOINT": AWS_ENDPOINT,
            "SNOWFLAKE_ACCOUNT": SNOWFLAKE_ACCOUNT,
            "SNOWFLAKE_WAREHOUSE": SNOWFLAKE_WAREHOUSE,
            "SNOWFLAKE_DATABASE": SNOWFLAKE_DATABASE,
            "SNOWFLAKE_SCHEMA": SNOWFLAKE_SCHEMA,
            "SNOWFLAKE_USER": SNOWFLAKE_USER,
            "SNOWFLAKE_PASSWORD": SNOWFLAKE_PASSWORD,
            "SNOWFLAKE_ROLE": SNOWFLAKE_ROLE,
            "S3_URI_LIST": "{{ task_instance.xcom_pull(task_ids='aggregate_processed_files') }}",
        },
    )

    gd_file_list = get_google_drive_file_list()
    ingested_file_list = ingest_file.expand(gd_file=gd_file_list)
    processed_file_list = process_file.expand(s3_raw_file_url=ingested_file_list)
    aggregated_file_list = aggregate_processed_files()

    (
        gd_file_list
        >> ingested_file_list
        >> processed_file_list
        >> aggregated_file_list
        >> load_to_snowflake
    )


payroll_dag()
