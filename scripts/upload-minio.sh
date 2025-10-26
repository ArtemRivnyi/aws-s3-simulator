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

# Check if file is provided
if [ $# -eq 0 ]; then
    echo "📤 Uploading all files from samples/ directory..."
    if [ -d "samples" ]; then
        aws_cmd s3 cp samples/ s3://$BUCKET_NAME/ --recursive
    else
        echo "❌ samples/ directory not found"
        exit 1
    fi
else
    FILE_PATH="$1"
    if [ -f "$FILE_PATH" ]; then
        FILE_NAME=$(basename "$FILE_PATH")
        echo "📤 Uploading file: $FILE_NAME"
        aws_cmd s3 cp "$FILE_PATH" s3://$BUCKET_NAME/
    else
        echo "❌ File not found: $FILE_PATH"
        exit 1
    fi
fi

echo ""
echo "✅ Upload completed!"
echo ""
"$SCRIPT_DIR/list-minio.sh"