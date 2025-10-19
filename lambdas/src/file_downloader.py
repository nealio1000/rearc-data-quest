import requests
import os
import logging
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor

contact_info = "nealiof1000@gmail.com"
user_agent_header = f"RearcDataQuest/1.0 ({contact_info})"

# Set up your headers
headers = {
    'Content-type': 'application/json',
    'User-Agent': user_agent_header
}

def download_bls_data(directory_url: str, local_folder: str) -> int:
    """
    Scrapes a web directory listing for file links and downloads them.

    :param directory_url: The URL of the directory listing (e.g., https://example.com/data/)
    :param local_folder: The local directory to save the files to.
    :return the count of bls files downloaded
    """
    logging.info(f"Starting download from: {directory_url}")

    # Create the local directory if it doesn't exist
    os.makedirs(local_folder, exist_ok=True)

    # Fetch and parse the directory HTML
    try:
        response = requests.get(directory_url, timeout=30, headers=headers)
        response.raise_for_status()  # Raise an exception for 4xx or 5xx status codes
        soup = BeautifulSoup(response.content, 'html.parser')
    except requests.exceptions.RequestException as e:
        logging.error(f"Error accessing or scraping directory {directory_url}: {e}")
        raise e

    file_links = []
    base_netloc = urlparse(directory_url).netloc
    
    # Extract file links
    for link in soup.find_all('a'):
        href = link.get('href')
        
        # Filter out links to parent directory ('../'), current directory ('./'), or sub-directories ('/')
        if href and not href.startswith('?') and not href.endswith('/'):
            
            # Construct the absolute URL
            absolute_url = urljoin(directory_url, href)
            
            # Ensure the link is on the same domain (optional but safer)
            if urlparse(absolute_url).netloc == base_netloc:
                file_links.append(absolute_url)

    if not file_links:
        logging.info("No files found or all links were filtered out.")
        return 0

    logging.info(f"Found {len(file_links)} files. Starting download...")
    
    # Download all files using multithreading for efficiency
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(download_single_file, url, local_folder) for url in file_links]
        
        for future in futures:
            future.result()
            
    logging.info(f"--- Download complete! Files saved in: {os.path.abspath(local_folder)} ---\n")
    return len(file_links)

def download_single_file(file_url, local_dir, params: dict = {}, override_filename: str | None = None):
    """
    Internal function to download a single file with streaming.

    :param file_url The URL of the file to download
    :param local_dir The path to the directory to store the file in
    :params params Any query parameters used in the fetch request for the file
    :params override_filename Optional value for if the caller wants to specify a name for the file
    :return The path to the file on the local filesystem
    """
    try:
        # Get filename from the URL path
        if not override_filename:
            filename = os.path.basename(urlparse(file_url).path)
        else:
            filename = override_filename
        local_path = os.path.join(local_dir, filename)

        # Use 'stream=True' to download large files without overloading memory
        with requests.get(file_url, stream=True, timeout=60, headers=headers, params=params) as r:
            r.raise_for_status()
            
            # Write file content in chunks
            with open(local_path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192): 
                    f.write(chunk)

        logging.info(f"✅ Downloaded: {filename}")
        return local_path

    except requests.exceptions.RequestException as e:
        logging.error(f"❌ Error downloading {filename}: {e}")
        return None
    except Exception as e:
        logging.error(f"❌ An unexpected error occurred for {filename}: {e}")
        return None

def download_population_data(url: str, local_folder: str, params: dict) -> int:
    """
    Downloads population data json from the url

    :param url: The URL of the directory listing (e.g., https://example.com/data/)
    :param local_folder: The local directory to save the files to.
    :return the count of population files downloaded (should be 1)
    """
    # Create the local directory if it doesn't exist
    os.makedirs(local_folder, exist_ok=True)
    
    try:
        download_single_file(file_url=url,local_dir=local_folder, params=params, override_filename='population.json')
        logging.info(f"--- Download complete! File saved in: {os.path.abspath(local_folder)} ---\n")
        return 1
    except Exception as e:
        return 0
    
