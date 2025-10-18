import boto3
import logging


# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Retrieves a file from S3 and logs its content.

    Args:
        event (dict): The event data, typically from an S3 trigger,
                      containing bucket and object information.
        context (object): The Lambda runtime context object.
    """
    s3_client = boto3.client('s3')

    # Extract bucket name and object key from the event
    # This assumes the Lambda is triggered by an S3 event
    if 'Records' in event:
        for record in event['Records']:
            if 's3' in record:
                bucket_name = record['s3']['bucket']['name']
                object_key = record['s3']['object']['key']

                logger.info(f"Retrieving file '{object_key}' from bucket '{bucket_name}'")

                try:
                    # Get the object from S3
                    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
                    file_content = response['Body'].read().decode('utf-8')

                    # Log the file content
                    logger.info(f"File content for '{object_key}':\n{file_content}")

                except Exception as e:
                    logger.error(f"Error retrieving or processing file '{object_key}': {e}")
                    raise # Re-raise the exception to indicate failure
            else:
                logger.warning("S3 event record not found in event.")
    else:
        # Handle cases where the Lambda is invoked manually or by other services
        # You would need to define bucket_name and object_key differently
        logger.info("Lambda invoked without S3 event. Manual or other trigger assumed.")
        # Example for manual invocation:
        # bucket_name = "your-s3-bucket-name"
        # object_key = "your-file-key.txt"
        # ... (rest of the S3 retrieval logic)