import boto3
import requests


def _get_google_drive_file_list(folder_id: str, api_key: str) -> list:
    """
    Get a list of files in a Google Drive folder.
    """
    url = f"https://www.googleapis.com/drive/v3/files?key={api_key}&q='{folder_id}' in parents&fields=files(id,name)"
    print(url)
    response = requests.get(url)
    file_list = response.json().get("files", [])
    return file_list


def _get_google_drive_file_content(file_id: str, api_key: str) -> bytes:
    response = requests.get(
        f"https://www.googleapis.com/drive/v3/files/{file_id}?key={api_key}&alt=media",
    )
    return response.content


def _ingest_file_to_s3(
    aws_access_key_id: str, aws_secret_access_key: str, object_name: str, data: bytes
) -> str:
    """
    Ingest a file to S3.
    """
    bucket_name = "payroll-project"
    region = "ap-southeast-2"
    
    s3_client = boto3.client(
        "s3",
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region,
        endpoint_url="https://s3.ap-southeast-2.amazonaws.com"  # modify end point if changing
    )
    # Check if the bucket exists, if not create it
    existing_buckets = s3_client.list_buckets()["Buckets"]
    if any(bucket["Name"] == bucket_name for bucket in existing_buckets):
        print(f"Bucket {bucket_name} already exists.")
    else:
        s3_client.create_bucket(Bucket=bucket_name)
        print(f"Bucket {bucket_name} created.")
    # Upload the file to raw
    key = f"raw/{object_name}"
    s3_client.put_object(Bucket=bucket_name, Key=key, Body=data)
    s3_raw_file_url = f"s3://{bucket_name}/{key}"
    return s3_raw_file_url
