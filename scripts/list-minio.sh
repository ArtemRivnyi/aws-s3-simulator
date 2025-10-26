#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Change to project directory
cd "$PROJECT_DIR"

# Get bucket name
BUCKET_NAME=$(get_bucket_name)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Bucket not found. Please run setup-minio.sh first"
    exit 1
fi

# Check if MinIO is running
if ! check_minio; then
    echo "❌ MinIO is not running. Please start it first with: docker-compose up -d"
    exit 1
fi

echo "📋 Contents of bucket: $BUCKET_NAME"
echo "========================================"

# List all objects with details
aws_cmd s3 ls s3://$BUCKET_NAME/ --recursive --human-readable

echo ""
echo "📊 Bucket statistics:"
aws_cmd s3 ls s3://$BUCKET_NAME/ --recursive --human-readable --summarize

echo ""
echo "🔍 Detailed object info:"
aws_cmd s3api list-objects-v2 --bucket $BUCKET_NAME \
    --query "Contents[].{Key:Key, Size:Size, Modified:LastModified}" \
    --output table 2>/dev/null || echo "No objects found"