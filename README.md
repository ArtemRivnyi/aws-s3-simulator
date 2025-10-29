# ⚙️ AWS S3 Simulator: Local MinIO for Development and Testing

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![MinIO](https://img.shields.io/badge/MinIO-C72E49?style=for-the-badge&logo=minio&logoColor=white)
![AWS S3](https://img.shields.io/badge/AWS_S3-569A31?style=for-the-badge&logo=amazons3&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Docker Compose](https://img.shields.io/badge/docker--compose-v2.40.0-blue?style=flat-square&logo=docker)](https://docs.docker.com/compose/)
[![MinIO Version](https://img.shields.io/badge/MinIO-RELEASE.2025--09--07-red?style=flat-square&logo=minio)](https://min.io/)
[![Tested](https://img.shields.io/badge/tests-passing-success?style=flat-square)](scripts/test-minio.sh)
[![Health Check](https://img.shields.io/badge/health-100%25-brightgreen?style=flat-square)](scripts/health-check.sh)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20windows-lightgrey?style=flat-square)](https://github.com/ArtemRivnyi/aws-s3-simulator)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Maintenance](https://img.shields.io/badge/maintained-yes-green.svg?style=flat-square)](https://github.com/ArtemRivnyi/aws-s3-simulator/graphs/commit-activity)
[![Tests](https://github.com/ArtemRivnyi/aws-s3-simulator/workflows/Test%20MinIO%20Setup/badge.svg)](https://github.com/ArtemRivnyi/aws-s3-simulator/actions)

A lightweight and fully self-contained tool designed to emulate the **Amazon S3** service locally using **MinIO**. This project is ideal for developers and testers who need a fast, reliable, and isolated environment to validate S3 API logic without relying on external cloud resources.

## 📝 Table of Contents

*   [✨ Overview and Project Goals](#-overview-and-project-goals)
*   [🎯 Key Features](#-key-features)
*   [🔧 Fixes and Improvements](#-fixes-and-improvements)
*   [🚀 Quick Start](#-quick-start)
    *   [Prerequisites](#prerequisites)
    *   [Setup and Run](#setup-and-run)
    *   [Access Credentials](#access-credentials)
    *   [Testing the Service](#testing-the-service)
*   [📋 System Access](#-system-access)
*   [🛠️ Utility Scripts](#%EF%B8%8F-utility-scripts)
*   [⚙️ Configuration](#%EF%B8%8F-configuration)
*   [💡 Important Notes](#-important-notes)
*   [🧰 Maintenance and Cleanup](#-maintenance-and-cleanup)
*   [🤝 Contributing](#-contributing)
*   [📜 Changelog](#-changelog)
*   [📄 License](#-license)
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
| **Project Cleanup** | Improved `cleanup-minio.sh` script with an interactive menu. | Offers safer and more controlled environment teardown. |

## 🔧 Fixes and Improvements

### Fixed Issues:
1.  **Container Name Fixed** in `scripts/common.sh` - changed from `minio-s3-simulator` to `aws-s3-simulator`.
2.  **Error in `health-check.sh` Fixed** - the `PROJECT_ROOT` variable has been added.
3.  **Web UI Port Fixed** in `scripts/test-minio.sh` - changed from 9001 to 9090.
4.  **Credentials Harmonized** - all scripts now use `admin/password123`.

### New Features:
-   **Added `setup-env.sh` script** - quick setup of environment variables for AWS CLI.

## 🚀 Quick Start

### Prerequisites

You must have the following tools installed on your system:

*   **Docker**
*   **Docker Compose** (v1 or v2)
*   **AWS CLI** (optional, but recommended for using the provided test scripts)

### 1. Launch MinIO

```bash
docker-compose up -d
```

### 2. Configure AWS CLI (required for each new terminal session)

```bash
source scripts/setup-env.sh
```

### 3. Verification

```bash
# Run all tests
./scripts/test-minio.sh

# Check system health
./scripts/health-check.sh

# List buckets
aws s3 ls --endpoint-url http://localhost:9000
```

## 📋 System Access

- **API Endpoint**: `http://localhost:9000`
- **Web Console**: `http://localhost:9090`
- **Login**: `admin`
- **Password**: `password123`

## 🛠️ Utility Scripts

| Script | Description |
|--------|----------|
| `setup-env.sh` | Sets up AWS CLI environment variables |
| `test-minio.sh` | Comprehensive MinIO testing (health check, bucket operations, file upload) |
| `health-check.sh` | Checks system status (Docker, container, network, AWS CLI) |
| `common.sh` | Shared functions for all scripts |
| `cleanup-minio.sh` | Stops and removes the container with an interactive menu for data removal |

## ⚙️ Configuration

Credentials and settings are located in the `.env` file:
```env
# MinIO Configuration
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123

# AWS CLI Configuration
AWS_ACCESS_KEY_ID=admin
AWS_SECRET_ACCESS_KEY=password123
AWS_DEFAULT_REGION=us-east-1
```

**Note**: Credentials can be changed in `.env`, after which the container must be restarted:
```bash
docker-compose down
docker-compose up -d
```

## 💡 Important Notes

- AWS CLI environment variables must be exported for each new terminal session using the command `source scripts/setup-env.sh`.
- MinIO uses custom credentials `admin/password123` (configured in `.env`).
- All data is stored in `./minio_data` and persists between restarts.

## 🧰 Maintenance and Cleanup

The `scripts/cleanup-minio.sh` script now provides an interactive menu for safely stopping the container and optionally removing the persistent data.

### Using the Cleanup Script

```bash
./scripts/cleanup-minio.sh
```

### Troubleshooting

If you encounter issues, check the container logs:

```bash
docker-compose logs -f
```

---

## 📜 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## 🤝 Contributing
This is a personal portfolio project, but suggestions for improvements to the CI/CD pipeline or code structure are welcome.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Maintainer

**Artem Rivnyi** — Junior Technical Support / DevOps Enthusiast

* 📧 [artemrivnyi@outlook.com](mailto:artemrivnyi@outlook.com)  
* 🔗 [LinkedIn](https://www.linkedin.com/in/artem-rivnyi/)  
* 🌐 [Personal Projects](https://personal-page-devops.onrender.com/)  
* 💻 [GitHub](https://github.com/ArtemRivnyi)
