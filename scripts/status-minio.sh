#!/bin/bash

echo "🔍 MinIO Status Check"
echo "===================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    echo "💡 Please start Docker Desktop"
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "minio-s3-simulator"; then
    echo "✅ MinIO container exists"
    
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q "minio-s3-simulator"; then
        echo "✅ MinIO container is RUNNING"
        
        # Show container details
        echo ""
        echo "📊 Container Details:"
        docker ps --filter "name=minio-s3-simulator" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
    else
        echo "⚠️  MinIO container exists but is STOPPED"
        echo ""
        echo "💡 Start it with: docker-compose up -d"
        exit 1
    fi
else
    echo "❌ MinIO container does not exist"
    echo ""
    echo "💡 Create and start it with: ./scripts/setup-minio.sh"
    exit 1
fi

echo ""
echo "🌐 Checking MinIO API..."

# Check if API is responding
if curl -s -f http://localhost:9000/minio/health/live > /dev/null 2>&1; then
    echo "✅ MinIO API is responding (http://localhost:9000)"
else
    echo "⚠️  MinIO API not responding yet (may still be starting)"
    echo "💡 Wait a few seconds and try: curl http://localhost:9000/minio/health/live"
fi

echo ""
echo "🌐 Checking Web Console..."

# Check if Web UI is accessible
if curl -s -f http://localhost:9090 > /dev/null 2>&1; then
    echo "✅ Web Console is accessible (http://localhost:9090)"
else
    echo "⚠️  Web Console not responding yet"
fi

echo ""
echo "📌 Access Information:"
echo "   🌐 Web UI: http://localhost:9090"
echo "   📚 API: http://localhost:9000"
echo "   🔑 Username: admin"
echo "   🔑 Password: password123"

echo ""
echo "💡 Quick Commands:"
echo "   View logs: docker-compose logs -f minio"
echo "   Restart: docker-compose restart"
echo "   Stop: docker-compose down"

# Try to get bucket name
echo ""
if [ -f .s3_bucket_name.txt ]; then
    BUCKET_NAME=$(cat .s3_bucket_name.txt)
    echo "📦 Current bucket: $BUCKET_NAME"
    
    # Try to list bucket
    if command -v aws &> /dev/null; then
        export AWS_ACCESS_KEY_ID=admin
        export AWS_SECRET_ACCESS_KEY=password123
        export AWS_DEFAULT_REGION=us-east-1
        
        echo ""
        echo "📋 Trying to list bucket contents..."
        if aws --endpoint-url=http://localhost:9000 s3 ls s3://$BUCKET_NAME/ 2>/dev/null; then
            echo "✅ Successfully connected to S3!"
        else
            echo "⚠️  Could not list bucket (MinIO may still be starting)"
        fi
    fi
else
    echo "ℹ️  No bucket created yet"
fi