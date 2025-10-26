#!/bin/bash

echo "🔍 Checking port availability..."
echo ""

# Function to check if port is in use
check_port() {
    local port=$1
    local port_name=$2
    
    if command -v netstat &> /dev/null; then
        # Using netstat (Windows/Linux)
        if netstat -an | grep ":$port" | grep -q "LISTEN"; then
            echo "❌ Port $port ($port_name) is BUSY"
            echo "   To find what's using it:"
            echo "   Windows: netstat -ano | findstr :$port"
            echo "   Linux/Mac: lsof -i :$port"
            return 1
        else
            echo "✅ Port $port ($port_name) is FREE"
            return 0
        fi
    elif command -v lsof &> /dev/null; then
        # Using lsof (Linux/Mac)
        if lsof -i :$port > /dev/null 2>&1; then
            echo "❌ Port $port ($port_name) is BUSY"
            lsof -i :$port
            return 1
        else
            echo "✅ Port $port ($port_name) is FREE"
            return 0
        fi
    else
        echo "⚠️  Cannot check port $port - netstat/lsof not available"
        return 0
    fi
}

# Check required ports
echo "Checking MinIO ports..."
echo "─────────────────────────"

all_free=true

check_port 9000 "S3 API" || all_free=false
check_port 9090 "Web Console" || all_free=false

echo ""
echo "─────────────────────────"

if [ "$all_free" = true ]; then
    echo "✅ All required ports are available!"
    echo ""
    echo "You can proceed with: ./scripts/setup-minio.sh"
else
    echo "❌ Some ports are in use!"
    echo ""
    echo "📝 Solutions:"
    echo "   1. Stop the application using these ports"
    echo "   2. Change ports in docker-compose.yml"
    echo "   3. On Windows, try: net stop winnat && net start winnat"
    echo ""
    echo "To find what's using a port on Windows:"
    echo "   netstat -ano | findstr :9000"
    echo "   netstat -ano | findstr :9090"
    echo ""
    echo "To kill a process by PID on Windows:"
    echo "   taskkill /PID <PID> /F"
    exit 1
fi