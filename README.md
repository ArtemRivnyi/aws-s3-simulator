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
*   [💡 Use Cases: When to use instead of real AWS S3](#-use-cases-when-to-use-instead-of-real-aws-s3)
*   [💰 Cost Savings Example](#-cost-savings-example)
*   [🔗 Integration Examples](#-integration-examples)
*   [🔧 Fixes and Improvements](#-fixes-and-improvements)
*   [🚀 Quick Start](#-quick-start)
    *   [Prerequisites](#prerequisites)
    *   [Setup and Run](#setup-and-run)
    *   [Access Credentials](#access-credentials)
    *   [Testing the Service](#testing-the-service)
*   [📋 System Access](#-system-access)
*   [🛠️ Utility Scripts](#%EF%B8%8F-utility-scripts)
*   [⚙️ Configuration](#%EF%B8%8F-configuration)
*   [⚠️ Integrity and Functionality Check Report](#-integrity-and-functionality-check-report)
*   [🧰 Maintenance and Cleanup](#-maintenance-and-cleanup)
*   [💡 Important Notes](#-important-notes)
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

## 💡 Use Cases: When to use instead of real AWS S3

The `aws-s3-simulator` is an indispensable tool for modern development workflows, offering a local, zero-cost alternative to the live AWS S3 service.

| Use Case | Description | Benefit |
| :--- | :--- | :--- |
| **Unit and Integration Testing** | Running automated tests that require S3 interactions (e.g., file uploads, downloads, listing buckets) without network latency or external dependencies. | **Speed & Reliability:** Tests run instantly and are immune to AWS service outages or network issues. |
| **Local Development** | Developing and debugging features that rely on S3, such as image processing pipelines, data ingestion, or file storage logic. | **Isolation:** Work in a completely isolated environment, preventing accidental modification of production or staging data. |
| **CI/CD Pipelines** | Executing end-to-end tests in a Continuous Integration environment where spinning up real cloud resources is slow or costly. | **Efficiency:** Fast setup and teardown within the CI runner, significantly reducing build times and costs. |
| **Offline Work** | Developing and testing S3-dependent features without an active internet connection. | **Flexibility:** Maintain productivity regardless of network availability. |

## 💰 Cost Savings Example

Using the `aws-s3-simulator` for development and testing can lead to significant cost reductions, especially for teams with frequent build cycles or extensive test suites.

**Saves $X/month in AWS costs**

For a typical development team, costs are incurred through:
1.  **Storage:** Storing test data in S3 buckets.
2.  **Requests:** Thousands of `PUT`, `GET`, and `LIST` requests generated by automated tests and local development.
3.  **Data Transfer:** Transferring data in and out of S3 during testing.

By shifting these operations to the local simulator, all associated AWS costs are eliminated. For a project with a high volume of automated tests, this can easily translate to **hundreds of dollars per month** in savings on S3 API calls and storage fees.

## 🔗 Integration Examples

The simulator is designed to integrate seamlessly with any application or tool that uses the official AWS SDKs.

### Example 1: Python (Boto3)

To connect your Python application using the `boto3` library, simply override the `endpoint_url` parameter:

```python
import boto3

s3_client = boto3.client(
    's3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='admin',
    aws_secret_access_key='password123',
    region_name='us-east-1'
)

# Example: List all buckets
response = s3_client.list_buckets()
print("Buckets:", [bucket['Name'] for bucket in response['Buckets']])
```

### Example 2: Node.js (AWS SDK v3)

For Node.js applications, configure the S3 client with the local endpoint:

```javascript
import { S3Client, ListBucketsCommand } from "@aws-sdk/client-s3";

const s3Client = new S3Client({
  endpoint: "http://localhost:9000",
  forcePathStyle: true, // Required for MinIO
  credentials: {
    accessKeyId: "admin",
    secretAccessKey: "password123",
  },
  region: "us-east-1",
});

async function listBuckets() {
  try {
    const data = await s3Client.send(new ListBucketsCommand({}));
    console.log("Buckets:", data.Buckets.map(b => b.Name));
  } catch (err) {
    console.error(err);
  }
}

listBuckets();
```

## 🔧 Fixes and Improvements

### Fixed Issues:

1.  **Container Name Fixed** in `scripts/common.sh` - changed from `minio-s3-simulator` to `aws-s3-simulator`.
2.  **Error in `health-check.sh` Fixed** - the `PROJECT_ROOT` variable has been added.
3.  **Web UI Port Fixed** in `scripts/test-minio.sh` - changed from 9001 to 9090.
4.  **Credentials Harmonized** - all scripts now use `admin/password123`.

### New Features:

*   **Added `setup-env.sh` script** - quick setup of environment variables for AWS CLI.

## 🚀 Quick Start

### Prerequisites

You must have the following tools installed on your system:

*   **Docker**
*   **Docker Compose** (v1 or v2)
*   **AWS CLI** (optional, but recommended for using the provided test scripts)

### 1\. Launch MinIO

```bash
docker-compose up -d
```

### 2\. Configure AWS CLI (required for each new terminal session)

```bash
source scripts/setup-env.sh
```

### 3\. Verification

```bash
# Run all tests
./scripts/test-minio.sh

# Check system health
./scripts/health-check.sh

# List buckets
aws s3 ls --endpoint-url http://localhost:9000
```

## 📋 System Access

*   **API Endpoint**: `http://localhost:9000`
*   **Web Console**: `http://localhost:9090`
*   **Login**: `admin`
*   **Password**: `password123`

## 🛠️ Utility Scripts

| Script | Description |
| --- | --- |
| `setup-env.sh` | Sets up AWS CLI environment variables |
| `test-minio.sh` | Comprehensive MinIO testing (health check, bucket operations, file upload) |
| `health-check.sh` | Checks system status (Docker, container, network, AWS CLI) |
| `common.sh` | Shared functions for all scripts |
| `cleanup-minio.sh` | Stops and removes the container with an interactive menu for data removal |

## ⚙️ Configuration

Credentials and settings are located in the `.env` file:

```dotenv
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

## ⚠️ Integrity and Functionality Check Report

The full report on the simulator's integrity and functionality checks, including detailed test results and environment validation, has been moved to a dedicated file.

**[View the full TESTING.md report here.](./TESTING.md)**

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

## 💡 Important Notes

*   AWS CLI environment variables must be exported for each new terminal session using the command `source scripts/setup-env.sh`.
*   MinIO uses custom credentials `admin/password123` (configured in `.env`).
*   All data is stored in `./minio_data` and persists between restarts.

## 🤝 Contributing

This is a personal portfolio project, but suggestions for improvements to the CI/CD pipeline or code structure are welcome.

## 📜 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Maintainer

**Artem Rivnyi** — Junior Technical Support / DevOps Enthusiast

*   📧 [artemrivnyi@outlook.com](mailto:artemrivnyi@outlook.com)
*   🔗 [LinkedIn](https://www.linkedin.com/in/artem-rivnyi/)
*   🌐 [Personal Projects](https://personal-page-devops.onrender.com/)
*   💻 [GitHub](https://github.com/ArtemRivnyi)