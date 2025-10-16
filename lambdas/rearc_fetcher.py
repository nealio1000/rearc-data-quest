import requests
import boto3
import os
from types_boto3_s3.client import S3Client
import json

def lambda_handler(event, context):
    """
    Retrieves a file from a specified URL and uploads it to an S3 bucket.

    Args:
        event (dict): The event object containing information for the Lambda invocation.
                      Expected to contain 'file_url' and 's3_bucket_name'.
        context (object): The runtime information of the Lambda invocation.
    """
    file_url = event.get('file_url')
    s3_bucket_name = event.get('s3_bucket_name')
    s3_key = event.get('s3_key') # Desired key (path/filename) in S3

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

        }

        # 3. Upload the file to S3
        s3.put_object(Bucket='', Key='', Body=json.dumps(some_json))

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
