#!/bin/bash
set -e
set -x

# Start MinIO in the background, redirecting logs
echo "Starting MinIO server..."
mkdir -p /data
minio server /data --console-address ":9001" > /tmp/minio.log 2>&1 &
MINIO_PID=$!

# Wait for MinIO to start with timeout (30s)
echo "Waiting for MinIO to start..."
timeout=30
while [ $timeout -gt 0 ]; do
    if curl -s http://localhost:9000/minio/health/live > /dev/null; then
        echo "MinIO started successfully!"
        break
    fi
    
    # Check if process is still running
    if ! kill -0 $MINIO_PID 2>/dev/null; then
        echo "MinIO process died unexpectedly!"
        echo "=== MinIO Logs ==="
        cat /tmp/minio.log
        echo "=================="
        exit 1
    fi
    
    sleep 1
    ((timeout--))
done

if [ $timeout -eq 0 ]; then
    echo "Timed out waiting for MinIO to start."
    echo "=== MinIO Logs ==="
    cat /tmp/minio.log
    echo "=================="
    exit 1
fi

# Configure MinIO alias (optional, for debugging)
# mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Create default bucket if it doesn't exist
# Note: We'll handle bucket creation in the app code or here if needed
# mc mb local/my-bucket || true

# Start Flask App
echo "Starting Flask application..."
exec gunicorn --config gunicorn_config.py app:app
