import pytest
from src.rearc_fetcher import sanitize_data
from src.s3_utils import synchronize_with_s3
from src.file_downloader import download_bls_data, download_population_data

def test_sanitize():
    assert sanitize_data() == "sanitized"