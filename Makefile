.PHONY: help setup start stop restart status test clean logs shell health permissions

# Load environment variables
include .env
export

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

permissions: ## Grant execution permissions to all scripts
	@echo "Granting execution permissions to scripts..."
	@chmod +x scripts/*.sh
	@echo "✓ Permissions granted"

setup: permissions ## Setup and start MinIO with initial configuration
	@echo "Setting up AWS S3 Simulator..."
	@./scripts/setup-minio.sh

start: permissions ## Start MinIO container
	@echo "Starting MinIO container..."
	@docker-compose up -d
	@echo "✓ MinIO started"
	@echo "  API Endpoint: http://localhost:$(MINIO_API_PORT)"
	@echo "  Console URL:  http://localhost:$(MINIO_CONSOLE_PORT)"
	@echo "  Username:     $(MINIO_ROOT_USER)"
	@echo "  Password:     $(MINIO_ROOT_PASSWORD)"

stop: ## Stop MinIO container
	@echo "Stopping MinIO container..."
	@docker-compose down
	@echo "✓ MinIO stopped"

restart: stop start ## Restart MinIO container

status: ## Check MinIO container status
	@./scripts/status-minio.sh

test: ## Run S3 API tests
	@echo "Running S3 API tests..."
	@./scripts/test-minio.sh

clean: ## Stop container and remove data
	@echo "Cleaning up AWS S3 Simulator..."
	@./scripts/cleanup-minio.sh
	@read -p "Do you want to remove all data? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Removing data directory..."; \
		rm -rf $(MINIO_DATA_PATH); \
		echo "✓ Data removed"; \
	fi

logs: ## Show MinIO container logs
	@docker-compose logs -f

shell: ## Open shell in MinIO container
	@docker-compose exec minio sh

health: ## Check MinIO health status
	@echo "Checking MinIO health..."
	@curl -sf http://localhost:$(MINIO_API_PORT)/minio/health/live > /dev/null && \
		echo "✓ MinIO is healthy" || \
		echo "✗ MinIO is not responding"

install-env: ## Copy .env.example to .env if not exists
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ Created .env file from .env.example"; \
		echo "⚠ Please review and update .env file with your settings"; \
	else \
		echo "✓ .env file already exists"; \
	fi

init: install-env setup ## Initialize project (copy env and setup)