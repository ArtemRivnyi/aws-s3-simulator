# Changelog

## [1.0.0] - 2025-10-27

### 🎉 Initial Release

#### Added
- MinIO S3-compatible storage setup with Docker Compose
- Complete test suite (`test-minio.sh`)
- Health check system (`health-check.sh`)
- Environment setup script (`setup-env.sh`)
- Cleanup utility (`cleanup-minio.sh`)
- Python and Node.js examples
- Comprehensive documentation

#### Fixed
- Container name mismatch in `common.sh` (minio-s3-simulator → aws-s3-simulator)
- Missing `PROJECT_ROOT` variable in `health-check.sh`
- Web UI port in `test-minio.sh` (9001 → 9090)
- Credentials consistency across all scripts

#### Configuration
- Unified credentials: `admin/password123`
- API Port: `9000`
- Console Port: `9090`
- Region: `us-east-1`

## [1.0.1] - 2025-11-02

### 📝 Documentation Update

#### Added
- New section: **Use Cases** ("When to use instead of real AWS S3").
- New section: **Cost Savings Example** ("Saves $X/month in AWS costs").
- New section: **Integration Examples** (Python Boto3 and Node.js AWS SDK v3).

#### Changed
- Moved **Integrity and Functionality Check Report** to a new dedicated file: `TESTING.md`.
- Updated **README.md** to link to `TESTING.md` and include all new sections.
- Completed all missing links in the **Maintainer** section.
