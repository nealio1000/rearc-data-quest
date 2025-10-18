import requests
import boto3
import os
import json
from datetime import date


def sanitize_data() -> str:
    return 'sanitized'

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
    bls_s3_key = f'bls-time-series/dt={current_date}/pr.data.0.Current'

    if not file_url or not s3_bucket_name or not bls_s3_key:
        return {
            'statusCode': 400,
            'body': 'Missing required parameters: file_url, s3_bucket_name, or s3_key'
        }

    try:
        # 1. Retrieve the file from the domain
        contact_info = "nealiof1000@gmail.com"
        user_agent_header = f"RearcDataQuest/1.0 ({contact_info})"

        # Set up your headers
        headers = {
            'Content-type': 'application/json',
            'User-Agent': user_agent_header
        }
        response = requests.get(file_url, stream=True, headers=headers)
        response.raise_for_status()  # Raise an exception for bad status codes

        # 2. Initialize S3 client
        s3 = boto3.client('s3')

        # 3. Upload the file to S3
        s3.put_object(Bucket=s3_bucket_name, Key=bls_s3_key, Body=response.content)

        population_url = 'https://honolulu-api.datausa.io/tesseract/data.jsonrecords'
        population_params = {
            'cube':	'acs_yg_total_population_1',
            'drilldowns':	['Year','Nation'],
            'locale':	'en',
            'measures':	'Population'
        }
        population_s3_key = 'population/population.json'

        response = requests.get(population_url, stream=True, headers=headers, params=population_params)
        s3.put_object(Bucket=s3_bucket_name, Key=population_s3_key, Body=response.content)

        return {
            'statusCode': 200,
            'body': f'File from {file_url} successfully uploaded to s3://{s3_bucket_name}/{bls_s3_key}'
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
