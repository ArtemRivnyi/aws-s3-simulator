#!/usr/bin/env python3
"""
Example script demonstrating how to use AWS S3 Simulator with boto3.
Install required package: pip install boto3
"""

import os
import boto3
from botocore.exceptions import ClientError


def create_s3_client():
    """Create and return an S3 client configured for local MinIO."""
    return boto3.client(
        's3',
        endpoint_url=os.getenv('S3_ENDPOINT', 'http://localhost:9000'),
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID', 'admin'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY', 'password123'),
        region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
    )


def list_buckets(s3_client):
    """List all S3 buckets."""
    try:
        response = s3_client.list_buckets()
        print("\n📦 Available buckets:")
        for bucket in response['Buckets']:
            print(f"  - {bucket['Name']}")
        return response['Buckets']
    except ClientError as e:
        print(f"Error listing buckets: {e}")
        return []


def create_bucket(s3_client, bucket_name):
    """Create a new S3 bucket."""
    try:
        s3_client.create_bucket(Bucket=bucket_name)
        print(f"✓ Bucket '{bucket_name}' created successfully")
    except ClientError as e:
        if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
            print(f"ℹ Bucket '{bucket_name}' already exists")
        else:
            print(f"Error creating bucket: {e}")


def upload_file(s3_client, bucket_name, file_path, object_name=None):
    """Upload a file to S3 bucket."""
    if object_name is None:
        object_name = os.path.basename(file_path)
    
    try:
        s3_client.upload_file(file_path, bucket_name, object_name)
        print(f"✓ File '{file_path}' uploaded as '{object_name}'")
    except ClientError as e:
        print(f"Error uploading file: {e}")


def list_objects(s3_client, bucket_name):
    """List all objects in a bucket."""
    try:
        response = s3_client.list_objects_v2(Bucket=bucket_name)
        
        if 'Contents' not in response:
            print(f"📭 Bucket '{bucket_name}' is empty")
            return []
        
        print(f"\n📄 Objects in '{bucket_name}':")
        for obj in response['Contents']:
            size_kb = obj['Size'] / 1024
            print(f"  - {obj['Key']} ({size_kb:.2f} KB)")
        
        return response['Contents']
    except ClientError as e:
        print(f"Error listing objects: {e}")
        return []


def download_file(s3_client, bucket_name, object_name, local_path):
    """Download a file from S3 bucket."""
    try:
        s3_client.download_file(bucket_name, object_name, local_path)
        print(f"✓ File '{object_name}' downloaded to '{local_path}'")
    except ClientError as e:
        print(f"Error downloading file: {e}")


def delete_object(s3_client, bucket_name, object_name):
    """Delete an object from S3 bucket."""
    try:
        s3_client.delete_object(Bucket=bucket_name, Key=object_name)
        print(f"✓ Object '{object_name}' deleted")
    except ClientError as e:
        print(f"Error deleting object: {e}")


def main():
    """Main function demonstrating S3 operations."""
    print("=" * 60)
    print("AWS S3 Simulator - Python Example (boto3)")
    print("=" * 60)
    
    # Create S3 client
    s3 = create_s3_client()
    
    # List existing buckets
    list_buckets(s3)
    
    # Create a test bucket
    test_bucket = 'python-test-bucket'
    create_bucket(s3, test_bucket)
    
    # Create a sample file
    sample_file = 'test_file.txt'
    with open(sample_file, 'w') as f:
        f.write('Hello from AWS S3 Simulator!\n')
        f.write('This is a test file created by Python example.\n')
    
    # Upload file
    upload_file(s3, test_bucket, sample_file)
    
    # List objects in bucket
    list_objects(s3, test_bucket)
    
    # Download file
    download_path = 'downloaded_file.txt'
    download_file(s3, test_bucket, sample_file, download_path)
    
    # Clean up local files
    if os.path.exists(sample_file):
        os.remove(sample_file)
    if os.path.exists(download_path):
        os.remove(download_path)
    
    print("\n" + "=" * 60)
    print("✓ Example completed successfully!")
    print("=" * 60)


if __name__ == '__main__':
    main()