import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    AWS Lambda handler function that processes SQS messages.
    Each message is expected to contain details about an S3 object (bucket and key).
    The function retrieves the S3 object and logs its content.
    """
    for record in event['Records']:
        try:
            # Parse the SQS message body
            message_body = json.loads(record['body'])
            
            # Extract S3 bucket and key from the message.
            # The structure of the SQS message body can vary depending on how it's sent.
            # This example assumes the S3 event notification structure.
            s3_info = message_body['Records'][0]['s3']
            bucket_name = s3_info['bucket']['name']
            object_key = s3_info['object']['key']

            logger.info(f"Processing S3 object: s3://{bucket_name}/{object_key}")

            # Retrieve the file from S3
            response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
            file_content = response['Body'].read().decode('utf-8')

            # Log the content of the file
            logger.info(f"Content of s3://{bucket_name}/{object_key}:\n{file_content}")

        except Exception as e:
            logger.error(f"Error processing SQS message: {e}")
            # Optionally, re-raise the exception or handle it for DLQ processing
            # raise e 

    return {
        'statusCode': 200,
        'body': json.dumps('Messages processed successfully!')
    }