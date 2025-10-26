#!/usr/bin/env bash
#
# health-check.sh
# Comprehensive health check for AWS S3 Simulator
#

set -euo pipefail

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Health check results
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  AWS S3 Simulator - Health Check${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

check_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((CHECKS_PASSED++))
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
  ((CHECKS_FAILED++))
}

check_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((CHECKS_WARNING++))
}

# Check 1: Docker daemon
check_docker() {
  echo "Checking Docker..."
  if command -v docker &> /dev/null; then
    check_pass "Docker is installed"
    
    if docker info &> /dev/null; then
      check_pass "Docker daemon is running"
      
      local version
      version=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
      check_pass "Docker version: ${version}"
    else
      check_fail "Docker daemon is not running"
      return 1
    fi
  else
    check_fail "Docker is not installed"
    return 1
  fi
}

# Check 2: Docker Compose
check_docker_compose() {
  echo ""
  echo "Checking Docker Compose..."
  
  if docker compose version &> /dev/null; then
    local version
    version=$(docker compose version --short)
    check_pass "Docker Compose v2 is available (${version})"
  elif docker-compose --version &> /dev/null; then
    local version
    version=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
    check_pass "Docker Compose v1 is available (${version})"
    check_warn "Consider upgrading to Docker Compose v2"
  else
    check_fail "Docker Compose is not installed"
    return 1
  fi
}

# Check 3: Container status
check_container() {
  echo ""
  echo "Checking MinIO container..."
  
  if docker ps --format '{{.Names}}' | grep -q "^aws-s3-simulator$"; then
    check_pass "Container is running"
    
    local status
    status=$(docker inspect -f '{{.State.Health.Status}}' aws-s3-simulator 2>/dev/null || echo "unknown")
    
    case "${status}" in
      "healthy")
        check_pass "Container health status: healthy"
        ;;
      "unhealthy")
        check_fail "Container health status: unhealthy"
        ;;
      "starting")
        check_warn "Container health status: starting"
        ;;
      *)
        check_warn "Container health status: ${status}"
        ;;
    esac
    
    # Check uptime
    local started
    started=$(docker inspect -f '{{.State.StartedAt}}' aws-s3-simulator 2>/dev/null)
    if [ -n "${started}" ]; then
      check_pass "Container started at: ${started}"
    fi
  else
    check_fail "Container is not running"
    return 1
  fi
}

# Check 4: Network connectivity
check_network() {
  echo ""
  echo "Checking network connectivity..."
  
  local api_port="${MINIO_API_PORT:-9000}"
  local console_port="${MINIO_CONSOLE_PORT:-9090}"
  
  # Check API endpoint
  if curl -sf "http://localhost:${api_port}/minio/health/live" > /dev/null 2>&1; then
    check_pass "MinIO API is accessible (port ${api_port})"
  else
    check_fail "MinIO API is not accessible (port ${api_port})"
  fi
  
  # Check Console endpoint
  if curl -sf "http://localhost:${console_port}" > /dev/null 2>&1; then
    check_pass "MinIO Console is accessible (port ${console_port})"
  else
    check_warn "MinIO Console is not accessible (port ${console_port})"
  fi
}

# Check 5: AWS CLI
check_aws_cli() {
  echo ""
  echo "Checking AWS CLI..."
  
  if command -v aws &> /dev/null; then
    local version
    version=$(aws --version 2>&1 | cut -d ' ' -f1 | cut -d '/' -f2)
    check_pass "AWS CLI is installed (${version})"
    
    # Try to list buckets
    if aws_cmd s3 ls &> /dev/null; then
      check_pass "AWS CLI can connect to MinIO"
    else
      check_warn "AWS CLI connection test failed"
    fi
  else
    check_warn "AWS CLI is not installed (optional)"
  fi
}

# Check 6: Data directory
check_data_dir() {
  echo ""
  echo "Checking data directory..."
  
  local data_path="${MINIO_DATA_PATH:-./minio_data}"
  
  if [ -d "${data_path}" ]; then
    check_pass "Data directory exists: ${data_path}"
    
    local size
    size=$(du -sh "${data_path}" 2>/dev/null | cut -f1)
    if [ -n "${size}" ]; then
      check_pass "Data directory size: ${size}"
    fi
    
    local bucket_count
    bucket_count=$(find "${data_path}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "${bucket_count}" -gt 0 ]; then
      check_pass "Buckets found: ${bucket_count}"
    else
      check_warn "No buckets found in data directory"
    fi
  else
    check_warn "Data directory does not exist: ${data_path}"
  fi
}

# Check 7: Environment configuration
check_environment() {
  echo ""
  echo "Checking environment configuration..."
  
  if [ -f "${PROJECT_ROOT}/.env" ]; then
    check_pass "Environment file exists (.env)"
    
    # Check for critical variables
    if grep -q "MINIO_ROOT_USER" "${PROJECT_ROOT}/.env"; then
      check_pass "MINIO_ROOT_USER is configured"
    else
      check_warn "MINIO_ROOT_USER not found in .env"
    fi
    
    if grep -q "MINIO_ROOT_PASSWORD" "${PROJECT_ROOT}/.env"; then
      check_pass "MINIO_ROOT_PASSWORD is configured"
    else
      check_warn "MINIO_ROOT_PASSWORD not found in .env"
    fi
  else
    check_warn "Environment file not found (.env)"
    check_warn "Using default configuration"
  fi
}

# Print summary
print_summary() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  Summary${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}Passed:${NC}   ${CHECKS_PASSED}"
  echo -e "  ${YELLOW}Warnings:${NC} ${CHECKS_WARNING}"
  echo -e "  ${RED}Failed:${NC}   ${CHECKS_FAILED}"
  echo ""
  
  if [ ${CHECKS_FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    
    if [ ${CHECKS_WARNING} -gt 0 ]; then
      echo -e "${YELLOW}⚠ Some warnings detected. Review above for details.${NC}"
    fi
    
    echo ""
    echo "Access points:"
    echo "  • API:     http://localhost:${MINIO_API_PORT:-9000}"
    echo "  • Console: http://localhost:${MINIO_CONSOLE_PORT:-9090}"
    echo ""
    
    return 0
  else
    echo -e "${RED}✗ Some checks failed. Please review the errors above.${NC}"
    echo ""
    return 1
  fi
}

# Main execution
main() {
  print_header
  
  check_docker || true
  check_docker_compose || true
  check_container || true
  check_network || true
  check_aws_cli || true
  check_data_dir || true
  check_environment || true
  
  print_summary
}

main "$@"