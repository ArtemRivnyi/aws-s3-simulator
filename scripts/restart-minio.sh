#!/bin/bash

echo "🔄 Restarting MinIO..."
echo "====================="
echo ""

# Restart container
docker-compose restart

echo ""
echo "⏳ Waiting for MinIO to be ready..."
sleep 5

# Check status
echo ""
./scripts/status-minio.sh