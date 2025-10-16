import requests
import boto3
import os
from types_boto3_s3.client import S3Client
import json
from datetime import date

def lambda_handler(event, context):
    """
    Retrieves a file from a specified URL and uploads it to an S3 bucket.

    Args:
        event (dict): The event object containing information for the Lambda invocation.
                      Expected to contain 'file_url' and 's3_bucket_name'.
        context (object): The runtime information of the Lambda invocation.
    """
    file_url = 'https://download.bls.gov/pub/time.series/pr/pr.data.0.Current'
    s3_bucket_name = 'rearc-quest-data-bucket'
    current_date = date.today().strftime("%Y-%m-%d")
    s3_key = f'bls-time-series/dt={current_date}/pr.data.0.Current'

    if not file_url or not s3_bucket_name or not s3_key:
        return {
            'statusCode': 400,
            'body': 'Missing required parameters: file_url, s3_bucket_name, or s3_key'
        }

    try:
        # 1. Retrieve the file from the domain
        response = requests.get(file_url, stream=True)
        response.raise_for_status()  # Raise an exception for bad status codes

        # 2. Initialize S3 client
        s3: S3Client = boto3.client('s3')

        some_json = {
            "test": "data"
        }

        # 3. Upload the file to S3
        s3.put_object(Bucket=s3_bucket_name, Key=s3_key, Body=json.dumps(some_json))

        return {
            'statusCode': 200,
            'body': f'File from {file_url} successfully uploaded to s3://{s3_bucket_name}/{s3_key}'
        }

    except requests.exceptions.RequestException as e:
        print(f"Error fetching file from URL: {e}")
        return {
            'statusCode': 500,
            'body': f'Error fetching file: {str(e)}'
        }
    except Exception as e:
        print(f"Error uploading file to S3: {e}")
        return {
            'statusCode': 500,
            'body': f'Error uploading to S3: {str(e)}'
        }
