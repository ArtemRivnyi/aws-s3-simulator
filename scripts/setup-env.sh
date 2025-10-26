#!/bin/bash
# Setup AWS CLI environment for MinIO
export AWS_ACCESS_KEY_ID=admin
export AWS_SECRET_ACCESS_KEY=password123
export AWS_DEFAULT_REGION=us-east-1
echo "✅ AWS environment configured!"
echo "You can now use: aws s3 ls --endpoint-url http://localhost:9000"
