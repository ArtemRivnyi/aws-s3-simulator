import pytest
from moto import mock_aws
import boto3
import os
from unittest import mock
from api.app import create_app

@pytest.fixture(autouse=True)
def mock_env():
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_REGION'] = 'us-east-1'
    os.environ['AWS_ENDPOINT_URL'] = '' 

@pytest.fixture
def s3_client():
    with mock_aws():
        conn = boto3.client("s3", region_name="us-east-1")
        yield conn

@pytest.fixture
def app(s3_client):
    # Mock PrometheusMetrics
    with mock.patch('api.app.PrometheusMetrics'):
        # We need to make sure the app uses the mocked s3 client
        # Since s3 is global in routes.py, we need to patch it or reload the module
        # But simpler is to patch the S3Client class or the instance in routes
        
        from api.routes import s3
        # Re-initialize the client inside the mock context
        s3.client = boto3.client("s3", region_name="us-east-1")
        
        app = create_app()
        app.config.update({
            "TESTING": True,
        })
        yield app

@pytest.fixture
def client(app):
    return app.test_client()
