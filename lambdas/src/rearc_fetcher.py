import requests
import logging
from s3_utils import synchronize_with_s3 # to run locally you may need to remove src.
from file_downloader import download_bls_data, download_population_data # to run locally you may need to remove src.

# Set up logging for detailed output
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def lambda_handler(event, context):
    """
    Retrieves a file from a specified URL and uploads it to an S3 bucket.

    Args:
        event (dict): The event object containing information for the Lambda invocation.
                    Currently unused but could be adapted to make the lambda more dynamic
        context (object): The runtime information of the Lambda invocation.
    """

    # These could be configurable using the event json in a production setting to make the lambda more dynamic
    bls_dir_url = 'https://download.bls.gov/pub/time.series/pr/'
    s3_bucket_name = 'rearc-quest-raw-data-bucket'
    population_url = 'https://honolulu-api.datausa.io/tesseract/data.jsonrecords?cube=acs_yg_total_population_1&drilldowns=Year%2CNation&locale=en&measures=Population'
    population_params = {
        'cube':	'acs_yg_total_population_1',
        'drilldowns':	'Year,Nation',
        'measures':	'Population'
    }

    try:
        # Retrieve the BLS files
        bls_downloaded_count = download_bls_data(directory_url=bls_dir_url, local_folder='/tmp/bls-data')

        # Retrieve the population data json file
        population_data_count = download_population_data(url=population_url, local_folder = '/tmp/population', params=population_params)

        # Synchronize BLS Data with S3
        if bls_downloaded_count > 0:
            bls_files_updated_or_added, bls_files_deleted = synchronize_with_s3('/tmp/bls-data', s3_bucket_name)
        else:
            logging.error('0 BLS Files were downloaded, cannot perform synchroniziation with s3 bucket')
            raise Exception('0 BLS Files were downloaded, cannot perform synchroniziation with s3 bucket')

        # Synchronize Population Data with S3
        if population_data_count > 0:
            population_updated_or_added, population_deleted = synchronize_with_s3('/tmp/population', s3_bucket_name)
        else:
            logging.error('0 population data files download, cannot perform synchronization with s3 bucket')
            raise Exception('0 population data files download, cannot perform synchronization with s3 bucket')
        
        files_updated_or_added = bls_files_updated_or_added + population_updated_or_added
        files_removed = bls_files_deleted + population_deleted

        logging.info(f'Fetcher Lambda completed successfully, updated/added {files_updated_or_added} files, removed {files_removed} files')

        return {
            'statusCode': 200,
            'body': f'Fetcher Lambda completed successfully, updated/added {files_updated_or_added} files, removed {files_removed} files'
        }

    except requests.exceptions.RequestException as e:
        logging.error(f"Error fetching file from URL: {e}")
        return {
            'statusCode': 500,
            'body': f'Error fetching file: {str(e)}'
        }
    except Exception as e:
        logging.error(f"Error uploading file to S3: {e}")
        return {
            'statusCode': 500,
            'body': f'Error uploading to S3: {str(e)}'
        }


if __name__ == '__main__':
    lambda_handler(event={},context={})