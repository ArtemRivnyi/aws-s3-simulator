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

echo "🧹 Cleaning up resources..."
echo ""

# Ask for confirmation
read -p "⚠️  This will delete all data and stop MinIO. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Delete bucket if exists
if [ -n "$BUCKET_NAME" ]; then
    echo "🗑️  Deleting bucket: $BUCKET_NAME"
    aws_cmd s3 rb s3://$BUCKET_NAME --force 2>/dev/null || echo "Bucket already deleted or doesn't exist"
    rm -f .s3_bucket_name.txt
fi

# Remove sample files
echo "🗑️  Removing sample files..."
rm -rf samples/

# Stop MinIO
echo "🐳 Stopping MinIO..."
docker-compose down

# Remove MinIO data
echo "🗑️  Removing MinIO data..."
rm -rf minio_data/

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "💡 To start again, run: ./scripts/setup-minio.sh"
```

## 9. .gitignore
```
# MinIO data directory
minio_data/

# Sample files directory
samples/

# Downloads directory
downloads/

# Bucket name tracking file
.s3_bucket_name.txt

# Demo files
demo_file.txt
downloaded_demo_file.txt

# Node.js
node_modules/
package-lock.json

# Python
__pycache__/
*.py[cod]
.Python
venv/

# OS files
.DS_Store
Thumbs.db
*~

# IDE files
.vscode/
.idea/
*.swp

# Logs
*.log

# Temporary files
*.tmp
*.temp

# Environment files
.env
.env.local