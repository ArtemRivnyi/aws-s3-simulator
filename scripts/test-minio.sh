#!/bin/bash

echo "🧪 Testing MinIO Connection"
echo "============================"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Change to project directory
cd "$PROJECT_DIR"

# Test MinIO health
echo "🔍 Test 1/4: Testing MinIO health endpoint..."
if check_minio; then
    echo "   ✅ MinIO is healthy and responding"
else
    echo "   ❌ MinIO is not responding"
    echo "   💡 Start MinIO with: docker-compose up -d"
    exit 1
fi

# Configure environment
setup_environment

# Test AWS CLI connection
echo ""
echo "🔍 Test 2/4: Testing AWS CLI connection..."
if aws_cmd s3 ls 2>/dev/null; then
    echo "   ✅ AWS CLI connection working"
else
    echo "   ❌ AWS CLI connection failed"
    exit 1
fi

# Test bucket operations
BUCKET_NAME="test-bucket-$(date +%s)"
echo ""
echo "🔍 Test 3/4: Testing bucket creation..."
if aws_cmd s3 mb s3://$BUCKET_NAME 2>/dev/null; then
    echo "   ✅ Bucket creation working"
else
    echo "   ❌ Bucket creation failed"
    exit 1
fi

# Test file upload
echo ""
echo "🔍 Test 4/4: Testing file upload..."
echo "Test content $(date)" > /tmp/test-file.txt
if aws_cmd s3 cp /tmp/test-file.txt s3://$BUCKET_NAME/ 2>/dev/null; then
    echo "   ✅ File upload working"
    # Cleanup
    aws_cmd s3 rb s3://$BUCKET_NAME --force 2>/dev/null
    rm -f /tmp/test-file.txt
else
    echo "   ❌ File upload failed"
    aws_cmd s3 rb s3://$BUCKET_NAME 2>/dev/null
    exit 1
fi

echo ""
echo "🎉 All tests passed! MinIO is working correctly."
echo ""
echo "📌 MinIO Details:"
echo "   🌐 Web UI: http://localhost:9090"
echo "   📚 API Endpoint: http://localhost:9000"
echo "   🔑 Credentials: admin / password123"