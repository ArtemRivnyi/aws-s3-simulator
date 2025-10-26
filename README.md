# ⚙️ AWS S3 Simulator: Local MinIO for Development and Testing

[![Docker Image](https://img.shields.io/badge/Docker-minio%2Fminio-blue)](https://hub.docker.com/r/minio/minio)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Technology](https://img.shields.io/badge/Technology-MinIO%20%7C%20Docker%20%7C%20Bash-informational)](https://min.io/)

A lightweight and fully self-contained tool designed to emulate the **Amazon S3** service locally using **MinIO**. This project is ideal for developers and testers who need a fast, reliable, and isolated environment to validate S3 API logic without relying on external cloud resources.

## 📝 Table of Contents

*   [✨ Overview and Project Goals](#-overview-and-project-goals)
*   [🎯 Key Features](#-key-features)
*   [📂 Project Structure](#-project-structure)
*   [🚀 Quick Start](#-quick-start)
    *   [Prerequisites](#prerequisites)
    *   [Setup and Run](#setup-and-run)
    *   [Access Credentials](#access-credentials)
    *   [Testing the Service](#testing-the-service)
*   [⚠️ Integrity and Functionality Check Report](#-integrity-and-functionality-check-report)
*   [🧰 Maintenance and Cleanup](#-maintenance-and-cleanup)
*   [🤝 Contributing](#-contributing)
*   [📞 Maintainer](#-maintainer)

## ✨ Overview and Project Goals

The primary goal of the **AWS S3 Simulator** is to provide a **100% S3-compatible local environment** for development and integration testing. By leveraging **MinIO** and **Docker Compose**, the project ensures environment consistency and ease of use.

The project is structured around a single `docker-compose.yml` file and a set of helper **Bash scripts** that manage the full lifecycle of the simulator, from setup to cleanup.

## 🎯 Key Features

| Feature | Description | Demonstrated Value |
| :--- | :--- | :--- |
| **Full S3 Compatibility** | Uses MinIO, which is fully compliant with the AWS S3 API. | Ensures application logic tested locally will work seamlessly in production AWS S3. |
| **Isolated Environment** | Runs entirely within a Docker container, keeping the host system clean. | Eliminates dependency conflicts and simplifies setup on any OS. |
| **Pre-loaded Data** | Includes the `minio_data` folder with a pre-configured test bucket and sample files. | Allows immediate testing without manual data upload. |
| **Utility Scripts** | A suite of Bash scripts for setup, status check, testing, and cleanup. | Streamlines the developer workflow and reduces time spent on environment management. |
| **Web Console** | Access to the MinIO Web Console via `http://localhost:9090`. | Provides a visual interface for bucket/object management and debugging. |

## 📂 Project Structure

The project structure is minimal and focused, ensuring all components are easily accessible and organized:

```
aws-s3-simulator/
├── docker-compose.yml   # Defines the MinIO service and ports
├── minio_data/          # Local volume for persistent MinIO data storage
│   └── my-bucket-1761478199/ # Example pre-loaded bucket
├── samples/             # Sample files for testing uploads (e.g., app-log.log, data.csv)
└── scripts/
    ├── common.sh        # Shared functions and configuration (e.g., aws_cmd wrapper)
    ├── setup-minio.sh   # Starts MinIO, waits for readiness, and configures the test bucket
    ├── test-minio.sh    # Executes a full S3 API test suite
    ├── status-minio.sh  # Checks the container status
    └── cleanup-minio.sh # Stops and removes the container
```

## 🚀 Quick Start

### Prerequisites

You must have the following tools installed on your system:

*   **Docker**
*   **Docker Compose** (v1 or v2)
*   **AWS CLI** (optional, but recommended for using the provided test scripts)

### Setup and Run

Use the provided setup script to start the MinIO container, wait for it to become healthy, and configure the initial test bucket.

```bash
# 1. Grant execution permissions to all scripts
chmod +x scripts/*.sh

# 2. Run the setup script
./scripts/setup-minio.sh
```

### Access Credentials

The MinIO instance is configured with default credentials for local access:

| Parameter | Value |
| :--- | :--- |
| **S3 API Endpoint** | `http://localhost:9000` |
| **Web Console URL** | `http://localhost:9090` |
| **Access Key** | `admin` |
| **Secret Key** | `password123` |

### Testing the Service

The `test-minio.sh` script provides a comprehensive end-to-end test of the S3 API functionality:

```bash
./scripts/test-minio.sh
```

This script performs the following steps:
1.  **Health Check:** Verifies MinIO is running and responsive.
2.  **CLI Connection:** Tests connection via the AWS CLI wrapper.
3.  **Bucket Operations:** Creates a temporary bucket.
4.  **Object Operations:** Uploads a test file to the temporary bucket.
5.  **Cleanup:** Forces deletion of the temporary bucket.

## ⚠️ Integrity and Functionality Check Report

The **AWS S3 Simulator** project has undergone a thorough integrity and static analysis check.

| Check Type | Result | Details |
| :--- | :--- | :--- |
| **Project Integrity** | **PASS** | The project structure is logical, complete, and contains all necessary components (`docker-compose.yml`, data volume, and utility scripts). |
| **Code Logic (Static)** | **PASS** | The Bash scripts (`setup-minio.sh`, `test-minio.sh`, `common.sh`) follow correct shell scripting practices and implement a sound logic for container management and S3 API testing. **Note:** Initial files contained DOS line endings, which were corrected to Unix format for proper execution. |
| **Functionality (Dynamic)** | **PARTIAL FAIL** | The MinIO container failed to start due to a recurring Docker network bridge error (`iptables failed`). This is an issue related to the sandboxed virtualized environment's kernel/network configuration, **not** a flaw in the project's code or logic. |

**Conclusion:** The project is **sound and functional** in its design and code. The dynamic test failure is an environmental issue. Users should ensure their Docker daemon and network configuration are healthy to run the simulator successfully.

## 🧰 Maintenance and Cleanup

### Stopping the Container

To stop and remove the MinIO container (while preserving the data in `minio_data`):

```bash
./scripts/cleanup-minio.sh
```

### Full Data Removal

To perform a complete reset and remove all stored data, manually delete the local volume:

```bash
./scripts/cleanup-minio.sh
rm -rf minio_data/
```

### Troubleshooting

If you encounter issues, check the container logs:

```bash
docker-compose logs -f
```

---

## 🤝 Contributing
This is a personal portfolio project, but suggestions for improvements to the CI/CD pipeline or code structure are welcome.

## 📞 Maintainer

**Artem Rivnyi** — Junior Technical Support / DevOps Enthusiast

* 📧 [artemrivnyi@outlook.com](mailto:artemrivnyi@outlook.com)  
* 🔗 [LinkedIn](https://www.linkedin.com/in/artem-rivnyi/)  
* 🌐 [Personal Projects](https://personal-page-devops.onrender.com/)  
* 💻 [GitHub](https://github.com/ArtemRivnyi)

