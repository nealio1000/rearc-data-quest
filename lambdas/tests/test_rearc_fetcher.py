import pytest
from src.rearc_fetcher import sanitize_data

def test_sanitize():
    assert sanitize_data() == "sanitized"