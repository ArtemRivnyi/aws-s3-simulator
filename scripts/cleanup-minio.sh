#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Change to project directory
cd "$PROJECT_DIR"

echo "🧹 AWS S3 Simulator - Cleanup Tool"
echo "===================================="
echo ""
echo "Select cleanup option:"
echo "  1) Delete all buckets (keep MinIO running)"
echo "  2) Delete all buckets and stop MinIO"
echo "  3) Full cleanup (buckets + data + stop MinIO)"
echo "  4) Cancel"
echo ""
read -p "Enter option (1-4): " option

case $option in
    1)
        echo ""
        echo "🗑️  Option 1: Deleting all buckets..."
        setup_environment
        
        echo "📋 Current buckets:"
        aws_cmd s3 ls
        echo ""
        
        read -p "⚠️  Confirm deletion? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            for bucket in $(aws_cmd s3 ls | awk '{print $3}'); do
                echo "   Deleting bucket: $bucket"
                aws_cmd s3 rb s3://$bucket --force 2>/dev/null || true
            done
            rm -f .s3_bucket_name.txt
            echo "✅ Buckets deleted!"
        else
            echo "❌ Cancelled"
        fi
        ;;
        
    2)
        echo ""
        echo "🗑️  Option 2: Deleting buckets and stopping MinIO..."
        setup_environment
        
        # Delete buckets
        for bucket in $(aws_cmd s3 ls 2>/dev/null | awk '{print $3}'); do
            echo "   Deleting bucket: $bucket"
            aws_cmd s3 rb s3://$bucket --force 2>/dev/null || true
        done
        rm -f .s3_bucket_name.txt
        
        # Stop MinIO
        echo "🐳 Stopping MinIO..."
        docker-compose down
        
        echo "✅ Cleanup completed!"
        ;;
        
    3)
        echo ""
        echo "🗑️  Option 3: Full cleanup..."
        echo ""
        read -p "⚠️  This will delete ALL data and stop MinIO. Continue? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            # Delete buckets
            setup_environment
            for bucket in $(aws_cmd s3 ls 2>/dev/null | awk '{print $3}'); do
                echo "   Deleting bucket: $bucket"
                aws_cmd s3 rb s3://$bucket --force 2>/dev/null || true
            done
            
            # Remove sample files
            echo "🗑️  Removing sample files..."
            rm -rf samples/ downloads/
            rm -f .s3_bucket_name.txt demo_file.txt downloaded_demo_file.txt
            
            # Stop MinIO
            echo "🐳 Stopping MinIO..."
            docker-compose down
            
            # Remove MinIO data
            echo "🗑️  Removing MinIO data..."
            rm -rf minio_data/
            
            echo ""
            echo "✅ Full cleanup completed!"
            echo ""
            echo "💡 To start again, run: docker-compose up -d"
        else
            echo "❌ Cancelled"
        fi
        ;;
        
    4)
        echo "❌ Cleanup cancelled"
        exit 0
        ;;
        
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac
