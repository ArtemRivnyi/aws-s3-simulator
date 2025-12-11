import pytest
from unittest.mock import MagicMock, patch
import sys
import os

# Add root directory to path so we can import app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app, s3_client

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture
def mock_minio():
    with patch('app.Minio') as mock:
        yield mock

def test_health_check(client, mock_minio):
    """Test health check endpoint"""
    # Mock s3_client connection status
    s3_client.connected = True
    
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert data['service'] == 'aws-s3-simulator'

def test_list_buckets(client, mock_minio):
    """Test list buckets endpoint"""
    # Mock the s3_client.client.list_buckets method
    mock_bucket = MagicMock()
    mock_bucket.name = 'test-bucket'
    s3_client.client = MagicMock()
    s3_client.client.list_buckets.return_value = [mock_bucket]
    s3_client.connected = True

    response = client.get('/api/v1/buckets/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'buckets' in data
    assert 'test-bucket' in data['buckets']

def test_create_bucket_missing_name(client):
    """Test create bucket with missing name"""
    response = client.post('/api/v1/buckets/', json={})
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data
