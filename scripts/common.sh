#!/bin/bash

# Common functions for MinIO

# Function to run AWS commands for MinIO
aws_cmd() {
    if command -v aws &> /dev/null; then
        aws --endpoint-url=http://localhost:9000 "$@"
    else
        # Use Docker container with AWS CLI for MinIO
        echo "🐳 Using Docker AWS CLI..."
        docker run --rm \
            --network host \
            -e AWS_ACCESS_KEY_ID=minioadmin \
            -e AWS_SECRET_ACCESS_KEY=minioadmin \
            -e AWS_DEFAULT_REGION=us-east-1 \
            amazon/aws-cli \
            --endpoint-url=http://localhost:9000 \
            "$@"
    fi
}

# Function to check if MinIO is running
check_minio() {
    # Check if container is running first
   if ! docker ps --format '{{.Names}}' | grep -q "aws-s3-simulator"; then
        return 1
    fi
    
    # Check if MinIO API is responding
    if curl -s -f http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for MinIO to be ready
wait_for_minio() {
    echo "⏳ Waiting for MinIO to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_minio; then
            echo "✅ MinIO is ready!"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts - MinIO not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    echo "⚠️  MinIO health check timeout - but container may still be working"
    echo "💡 Trying to proceed anyway..."
    sleep 3
    return 0  # Continue anyway, container might be slow but working
}

# Function to start MinIO if not running
start_minio() {
    # Check if container exists and is running
   if docker ps --format '{{.Names}}' | grep -q "aws-s3-simulator"; then
        echo "✅ MinIO container is already running"
        
        # Do a quick check if it's responding
        if check_minio; then
            echo "✅ MinIO API is responding"
            return 0
        else
            echo "⚠️  Container running but API not responding yet, waiting..."
            sleep 5
            return 0
        fi
    fi
    
    echo "🚀 MinIO is not running. Starting..."
    docker-compose up -d
    
    # Give it a moment to start
    sleep 3
    
    # Try to wait for it, but don't fail if timeout
    wait_for_minio || true
}

# Function to configure environment for MinIO
setup_environment() {
    export AWS_ACCESS_KEY_ID=admin
    export AWS_SECRET_ACCESS_KEY=password123
    export AWS_DEFAULT_REGION=us-east-1
}

# Function to get bucket name (create if not exists)
get_bucket_name() {
    if [ -f .s3_bucket_name.txt ]; then
        cat .s3_bucket_name.txt
    else
        BUCKET_NAME="my-bucket-$(date +%s)"
        echo $BUCKET_NAME > .s3_bucket_name.txt
        echo $BUCKET_NAME
    fi
}