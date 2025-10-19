import pytest
from rearc_fetcher import sanitize_data
from s3_utils import synchronize_with_s3
from file_downloader import download_bls_data, download_population_data

def test_sanitize():
    assert sanitize_data() == "sanitized"