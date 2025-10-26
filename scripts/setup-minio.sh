#!/bin/bash

echo "🚀 AWS S3 Simulator - MinIO Setup"
echo "===================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Change to project directory
cd "$PROJECT_DIR"

# Check ports before starting
echo "🔍 Checking port availability..."
if [ -f "$SCRIPT_DIR/check-ports.sh" ]; then
    bash "$SCRIPT_DIR/check-ports.sh" || {
        echo ""
        echo "⚠️  Port check failed. Please resolve port conflicts first."
        echo ""
        echo "💡 Quick fix for Windows:"
        echo "   Run as Administrator: net stop winnat && net start winnat"
        exit 1
    }
else
    echo "⚠️  Port check script not found, skipping..."
fi

echo ""

# Start MinIO if needed
start_minio

# Configure environment
echo "⚙️  Configuring environment..."
setup_environment

# Get or create bucket name
BUCKET_NAME=$(get_bucket_name)
echo "🆕 Using bucket: $BUCKET_NAME"

# Create bucket
echo "📦 Creating S3 bucket..."
aws_cmd s3 mb s3://$BUCKET_NAME 2>/dev/null || echo "Bucket already exists"

# Create sample files
echo "📝 Creating sample files..."
mkdir -p samples
echo "This is a test document for S3 demonstration with MinIO" > samples/sample-document.txt
echo "Project: AWS S3 Simulator" >> samples/sample-document.txt
echo "Date: $(date)" >> samples/sample-document.txt

cat > samples/app-log.log << EOF
2024-01-01 10:00:00 INFO: Application started with MinIO
2024-01-01 10:01:00 DEBUG: Initializing S3 client
2024-01-01 10:02:00 INFO: MinIO connection established
2024-01-01 10:03:00 INFO: Bucket created successfully
2024-01-01 10:04:00 DEBUG: Uploading test files
2024-01-01 10:05:00 INFO: Files uploaded successfully
EOF

cat > samples/config.json << EOF
{
    "project": "AWS S3 Simulator",
    "version": "1.0.0",
    "environment": "development",
    "storage": "minio",
    "endpoint": "http://localhost:9000",
    "bucket": "$BUCKET_NAME"
}
EOF

cat > samples/data.csv << EOF
ID,Name,Value,Count,Status
1,test1,100,5,active
2,test2,200,10,active
3,test3,150,7,inactive
4,test4,300,15,active
5,test5,250,12,active
EOF

# Upload files
echo "📤 Uploading files to bucket: $BUCKET_NAME"
aws_cmd s3 cp samples/ s3://$BUCKET_NAME/ --recursive

# List objects
echo ""
echo "📋 Bucket contents:"
aws_cmd s3 ls s3://$BUCKET_NAME/ --recursive --human-readable

echo ""
echo "✅ MinIO setup completed successfully!"
echo ""
echo "📌 Access Information:"
echo "   🌐 MinIO Web UI: http://localhost:9090"
echo "   🔑 Username: admin"
echo "   🔑 Password: password123"
echo "   📚 S3 Endpoint: http://localhost:9000"
echo "   📦 Bucket: $BUCKET_NAME"
echo ""
echo "💡 Next steps:"
echo "   • Run './scripts/list-minio.sh' to see bucket contents"
echo "   • Run './scripts/upload-minio.sh <file>' to upload files"
echo "   • Run './scripts/cleanup-minio.sh' to cleanup resources"