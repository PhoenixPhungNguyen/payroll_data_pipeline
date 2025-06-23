# Import the SparkSession module
import json
import os

from pyspark.sql import SparkSession

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_ENDPOINT = os.getenv("AWS_ENDPOINT")

SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WAREHOUSE")
SNOWFLAKE_DATABASE = os.getenv("SNOWFLAKE_DATABASE")
SNOWFLAKE_SCHEMA = os.getenv("SNOWFLAKE_SCHEMA")
SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.getenv("SNOWFLAKE_PASSWORD")
SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE")

S3_URI_LIST = os.getenv("S3_URI_LIST")


def _load_to_snowflake():
    spark = (
        SparkSession.builder.appName("LoadToSnowflake")
        .config(
            "spark.jars",
            "spark/jars/spark-snowflake_2.12-2.12.0-spark_3.3.jar,spark/jars/snowflake-jdbc-3.13.30.jar,spark/jars/aws-java-sdk-bundle-1.11.1026.jar,spark/jars/hadoop-aws-3.3.2.jar",
        )
        .config(
            "fs.s3a.aws.credentials.provider",
            "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider",
        )
        .config("fs.s3a.access.key", AWS_ACCESS_KEY_ID)
        .config("fs.s3a.secret.key", AWS_SECRET_ACCESS_KEY)
        .config(
            "fs.s3a.endpoint",
            AWS_ENDPOINT,
        )
        .config("fs.s3a.connection.ssl.enabled", "true")
        .config("fs.s3a.path.style.access", "true")
        .config("fs.s3a.attempts.maximum", "1")
        .getOrCreate()
    )
    s3_uri_list = json.loads(S3_URI_LIST.replace("'", '"'))
    # The url in S3_URI_LIST is expected to be in the format: s3://payroll-cdoguel/processed/file.parquet
    # We need to replace the s3:// prefix with s3a:// for Spark to read it correctly
    s3a_uri_list = [uri.replace("s3://", "s3a://") for uri in s3_uri_list]
    for file_path in s3a_uri_list:
        print(f"Reading: {file_path}")
        df = spark.read.parquet(f"{file_path}")
        sf_options = {
            "sfURL": f"https://{SNOWFLAKE_ACCOUNT}.snowflakecomputing.com",
            "sfWarehouse": SNOWFLAKE_WAREHOUSE,
            "sfDatabase": SNOWFLAKE_DATABASE,
            "sfSchema": SNOWFLAKE_SCHEMA,
            "sfUser": SNOWFLAKE_USER,
            "sfPassword": SNOWFLAKE_PASSWORD,
            "sfRole": SNOWFLAKE_ROLE,
        }
        table_name = f"LND_{file_path.split('/')[-1].split('.')[0]}"
        table = f"{SNOWFLAKE_SCHEMA}.{table_name}"
        df.write.format("snowflake").options(**sf_options).option(
            "dbtable", table
        ).mode("overwrite").save()
        print("=" * 100)
    os.system("kill %d" % os.getpid())


_load_to_snowflake()
