# Stage 1: Builder
FROM python:3.9-slim as builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends gcc

COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Runtime
FROM python:3.9-slim

WORKDIR /app

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install curl for healthcheck and wget for downloading minio
RUN apt-get update && \
  apt-get install -y --no-install-recommends curl wget && \
  rm -rf /var/lib/apt/lists/*

# Install MinIO
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio \
  && chmod +x minio \
  && mv minio /usr/local/bin/

# Copy wheels and install dependencies
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache /wheels/*

# Copy application files
COPY app.py .
COPY gunicorn_config.py .
COPY templates/ templates/
COPY static/ static/
COPY scripts/ scripts/

# Make start script executable
RUN chmod +x scripts/start.sh

# Change ownership to non-root user and create /data
RUN mkdir -p /data && chown -R appuser:appuser /app /usr/local/bin/minio /data

USER appuser

# Expose ports: 5000 (Flask), 9000 (MinIO API), 9001 (MinIO Console)
EXPOSE 5000 9000 9001

# Run with start script
ENTRYPOINT ["/bin/bash", "scripts/start.sh"]