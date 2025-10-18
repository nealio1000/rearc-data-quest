import requests
import boto3
import os
import json
from datetime import date
import logging
import hashlib
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor
from botocore.exceptions import ClientError

# Set up logging for detailed output
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


def calculate_md5(filepath, chunk_size=8192):
    """Calculates the MD5 hash of a local file for change detection."""
    try:
        hash_md5 = hashlib.md5()
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(chunk_size), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest().lower()
    except Exception as e:
        logging.error(f"Error calculating MD5 for {filepath}: {e}")
        return None

def get_local_manifest(source_dir):
    """
    Scans the local directory and returns a manifest of files (S3 Key: MD5 Hash).
    The relative path becomes the S3 Key.
    """
    local_manifest = {}
    
    if not os.path.isdir(source_dir):
        logging.error(f"Source directory not found: {source_dir}")
        return local_manifest

    logging.info(f"Scanning local directory: {source_dir}")
    
    for root, _, files in os.walk(source_dir):
        for filename in files:
            absolute_path = os.path.join(root, filename)
            
            # Create the S3 key (relative path, with forward slashes)
            s3_key = absolute_path.replace('/tmp/', '')
            
            file_md5 = calculate_md5(absolute_path)
            
            if file_md5:
                local_manifest[s3_key] = file_md5
    
    return local_manifest

def get_s3_manifest(s3_client, bucket_name, prefix: str):
    """
    Lists all objects in the S3 bucket and returns a manifest (S3 Key: ETag).
    """
    s3_manifest = {}
    try:
        paginator = s3_client.get_paginator('list_objects_v2')
        pages = paginator.paginate(Bucket=bucket_name, Prefix=prefix)

        logging.info(f"Scanning S3 bucket: {bucket_name}/{prefix}")
        
        for page in pages:
            if 'Contents' in page:
                for obj in page['Contents']:
                    # Strip quotes and convert ETag to lowercase for consistent comparison
                    etag = obj['ETag'].strip('"').lower()
                    s3_manifest[obj['Key']] = etag
        
    except ClientError as e:
        logging.error(f"Failed to list S3 objects. Check bucket name and permissions. Error: {e}")
        return {}
    except Exception as e:
        logging.error(f"An unexpected error occurred while scanning S3: {e}")
        return {}
        
    return s3_manifest

def synchronize_with_s3(source_dir, bucket_name, region='us-east-1'):
    """
    Compares local and S3 manifests and executes necessary uploads and deletions.
    """
    logging.info("Starting synchronization process...")

    updated_or_added_count = 0
    deleted_count = 0
    
    try:
        s3_client = boto3.client('s3', region_name=region)
    except Exception as e:
        logging.error(f"Could not initialize S3 client. Error: {e}")
        return updated_or_added_count, deleted_count

    local_manifest = get_local_manifest(source_dir)
    s3_manifest = get_s3_manifest(s3_client, bucket_name, prefix=source_dir.replace('/tmp/', '') + '/')
    
    if not local_manifest and not s3_manifest:
        logging.warning("No files found locally or in S3. Exiting sync.")
        return updated_or_added_count, deleted_count

    # 1. Determine files to upload (Additions or Modifications)
    files_to_upload = []
    for s3_key, local_md5 in local_manifest.items():
        # A file is new if its key is not in the S3 manifest
        # A file is modified if its local MD5 hash does not match the S3 ETag
        if s3_key not in s3_manifest or s3_manifest[s3_key] != local_md5:
            files_to_upload.append(s3_key)
            status = "NEW" if s3_key not in s3_manifest else "MODIFIED"
            logging.debug(f"{status}: {s3_key}")
        # Else: MD5 matches ETag, file is in sync, skip (efficiency achieved)

    # 2. Determine objects to delete (Local Deletions)
    files_to_delete = []
    for s3_key in s3_manifest.keys():
        # An object needs deletion if its key is in S3 but not in the local manifest
        if s3_key not in local_manifest:
            files_to_delete.append(s3_key)
            logging.debug(f"DELETED: {s3_key}")


    # --- EXECUTE ACTIONS ---

    # A. Execute Uploads/Updates
    if files_to_upload:
        logging.info(f"--- UPLOADING/UPDATING {len(files_to_upload)} files ---")
        for s3_key in files_to_upload:
            local_path = os.path.join('/tmp/', s3_key)
            try:
                # Use upload_file() for robust handling
                s3_client.upload_file(
                    Filename=local_path, 
                    Bucket=bucket_name, 
                    Key=s3_key
                )
                logging.info(f"Uploaded: {s3_key}")
            except ClientError as e:
                logging.error(f"Upload failed for {s3_key}. Error: {e}")
    else:
        logging.info("No local files detected as new or modified. Skipping uploads.")
        
    # B. Execute Deletions
    if files_to_delete:
        logging.info(f"--- DELETING {len(files_to_delete)} objects ---")
        
        # S3 delete_objects call requires keys to be batched (max 1000 per call)
        keys_to_delete = [{'Key': key} for key in files_to_delete]
        
        batch_size = 1000
        for i in range(0, len(keys_to_delete), batch_size):
            batch = keys_to_delete[i:i + batch_size]
            try:
                s3_client.delete_objects(
                    Bucket=bucket_name,
                    Delete={'Objects': batch, 'Quiet': True} 
                )
                logging.info(f"Successfully processed deletion batch of size {len(batch)}.")
            except ClientError as e:
                logging.error(f"Batch deletion failed. Error: {e}")
    else:
        logging.info("No files detected for deletion in S3. Skipping deletions.")

    logging.info("Synchronization complete.")
    updated_or_added_count = len(files_to_upload)
    deleted_count = len(files_to_delete)
    return updated_or_added_count, deleted_count