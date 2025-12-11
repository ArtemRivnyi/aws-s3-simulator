#!/bin/bash
set -e
set -x

# Start MinIO in the background
echo "Starting MinIO server..."
mkdir -p /data
minio server /data --console-address ":9001" &
MINIO_PID=$!

# Wait for MinIO to start
echo "Waiting for MinIO to start..."
until curl -s http://localhost:9000/minio/health/live; do
  sleep 1
done
echo "MinIO started!"

# Configure MinIO alias (optional, for debugging)
# mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Create default bucket if it doesn't exist
# Note: We'll handle bucket creation in the app code or here if needed
# mc mb local/my-bucket || true

# Start Flask App
echo "Starting Flask application..."
exec gunicorn --config gunicorn_config.py app:app
