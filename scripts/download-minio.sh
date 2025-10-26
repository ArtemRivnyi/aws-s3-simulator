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

# Create downloads directory
DOWNLOAD_DIR="downloads"
mkdir -p "$DOWNLOAD_DIR"

# Check if specific file is requested
if [ $# -eq 0 ]; then
    echo "📥 Downloading all files from bucket: $BUCKET_NAME"
    aws_cmd s3 cp s3://$BUCKET_NAME/ "$DOWNLOAD_DIR/" --recursive
else
    FILE_NAME="$1"
    echo "📥 Downloading file: $FILE_NAME"
    aws_cmd s3 cp s3://$BUCKET_NAME/$FILE_NAME "$DOWNLOAD_DIR/"
fi

echo ""
echo "✅ Download completed!"
echo "📁 Files saved to: $DOWNLOAD_DIR/"
echo ""
ls -lh "$DOWNLOAD_DIR/"