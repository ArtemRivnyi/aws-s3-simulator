#!/usr/bin/env bash
#
# validate-env.sh
# Validates that required environment variables are set and have valid values
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "🔍 Validating environment configuration..."
echo ""

# Check if .env file exists
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  echo -e "${RED}✗ Error: .env file not found${NC}"
  echo -e "${YELLOW}ℹ Run: cp .env.example .env${NC}"
  exit 1
fi

# Source the .env file
set -a
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/.env"
set +a

ERRORS=0

# Validation functions
validate_not_empty() {
  local var_name=$1
  local var_value=$2
  
  if [ -z "${var_value}" ]; then
    echo -e "${RED}✗ ${var_name} is empty${NC}"
    ((ERRORS++))
    return 1
  fi
  echo -e "${GREEN}✓ ${var_name} is set${NC}"
  return 0
}

validate_port() {
  local var_name=$1
  local port=$2
  
  if ! [[ "${port}" =~ ^[0-9]+$ ]] || [ "${port}" -lt 1 ] || [ "${port}" -gt 65535 ]; then
    echo -e "${RED}✗ ${var_name}=${port} is not a valid port (1-65535)${NC}"
    ((ERRORS++))
    return 1
  fi
  echo -e "${GREEN}✓ ${var_name}=${port} is valid${NC}"
  return 0
}

validate_boolean() {
  local var_name=$1
  local value=$2
  
  if [[ ! "${value}" =~ ^(true|false)$ ]]; then
    echo -e "${RED}✗ ${var_name}=${value} must be 'true' or 'false'${NC}"
    ((ERRORS++))
    return 1
  fi
  echo -e "${GREEN}✓ ${var_name}=${value} is valid${NC}"
  return 0
}

validate_password_strength() {
  local password=$1
  
  if [ ${#password} -lt 8 ]; then
    echo -e "${YELLOW}⚠ MINIO_ROOT_PASSWORD is shorter than 8 characters${NC}"
    echo -e "${YELLOW}  Consider using a stronger password for production${NC}"
  fi
}

# Validate required variables
echo "Checking required variables:"
validate_not_empty "MINIO_ROOT_USER" "${MINIO_ROOT_USER}"
validate_not_empty "MINIO_ROOT_PASSWORD" "${MINIO_ROOT_PASSWORD}"
validate_not_empty "AWS_ACCESS_KEY_ID" "${AWS_ACCESS_KEY_ID}"
validate_not_empty "AWS_SECRET_ACCESS_KEY" "${AWS_SECRET_ACCESS_KEY}"

echo ""
echo "Checking port configuration:"
validate_port "MINIO_API_PORT" "${MINIO_API_PORT}"
validate_port "MINIO_CONSOLE_PORT" "${MINIO_CONSOLE_PORT}"

# Check for port conflicts
if [ "${MINIO_API_PORT}" = "${MINIO_CONSOLE_PORT}" ]; then
  echo -e "${RED}✗ MINIO_API_PORT and MINIO_CONSOLE_PORT cannot be the same${NC}"
  ((ERRORS++))
fi

echo ""
echo "Checking optional variables:"
validate_not_empty "AWS_DEFAULT_REGION" "${AWS_DEFAULT_REGION:-}"
validate_not_empty "S3_ENDPOINT" "${S3_ENDPOINT:-}"
validate_not_empty "TEST_BUCKET_NAME" "${TEST_BUCKET_NAME:-}"
validate_boolean "DEBUG" "${DEBUG:-false}"

echo ""
echo "Security checks:"
validate_password_strength "${MINIO_ROOT_PASSWORD}"

# Check if using default credentials
if [ "${MINIO_ROOT_USER}" = "admin" ] && [ "${MINIO_ROOT_PASSWORD}" = "password123" ]; then
  echo -e "${YELLOW}⚠ Using default credentials (admin/password123)${NC}"
  echo -e "${YELLOW}  This is OK for local development, but change for production${NC}"
fi

# Check if S3_ENDPOINT matches port configuration
EXPECTED_ENDPOINT="http://localhost:${MINIO_API_PORT}"
if [ "${S3_ENDPOINT}" != "${EXPECTED_ENDPOINT}" ]; then
  echo -e "${YELLOW}⚠ S3_ENDPOINT doesn't match MINIO_API_PORT${NC}"
  echo -e "${YELLOW}  Expected: ${EXPECTED_ENDPOINT}${NC}"
  echo -e "${YELLOW}  Got: ${S3_ENDPOINT}${NC}"
fi

echo ""
echo "================================"

if [ ${ERRORS} -eq 0 ]; then
  echo -e "${GREEN}✓ Environment validation passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Environment validation failed with ${ERRORS} error(s)${NC}"
  exit 1
fi