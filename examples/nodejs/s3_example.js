#!/usr/bin/env node
/**
 * Example script demonstrating how to use AWS S3 Simulator with AWS SDK v3.
 * Install required packages:
 * npm install @aws-sdk/client-s3
 */

const fs = require('fs');
const {
  S3Client,
  ListBucketsCommand,
  CreateBucketCommand,
  PutObjectCommand,
  ListObjectsV2Command,
  GetObjectCommand,
  DeleteObjectCommand,
} = require('@aws-sdk/client-s3');

// Configure S3 client for local MinIO
const s3Client = new S3Client({
  endpoint: process.env.S3_ENDPOINT || 'http://localhost:9000',
  region: process.env.AWS_DEFAULT_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'admin',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'password123',
  },
  forcePathStyle: true, // Required for MinIO
});

/**
 * List all S3 buckets
 */
async function listBuckets() {
  try {
    const response = await s3Client.send(new ListBucketsCommand({}));
    console.log('\n📦 Available buckets:');
    response.Buckets.forEach((bucket) => {
      console.log(`  - ${bucket.Name}`);
    });
    return response.Buckets;
  } catch (error) {
    console.error('Error listing buckets:', error.message);
    return [];
  }
}

/**
 * Create a new S3 bucket
 */
async function createBucket(bucketName) {
  try {
    await s3Client.send(new CreateBucketCommand({ Bucket: bucketName }));
    console.log(`✓ Bucket '${bucketName}' created successfully`);
  } catch (error) {
    if (error.name === 'BucketAlreadyOwnedByYou') {
      console.log(`ℹ Bucket '${bucketName}' already exists`);
    } else {
      console.error('Error creating bucket:', error.message);
    }
  }
}

/**
 * Upload a file to S3 bucket
 */
async function uploadFile(bucketName, filePath, objectKey) {
  try {
    const fileContent = fs.readFileSync(filePath);
    await s3Client.send(
      new PutObjectCommand({
        Bucket: bucketName,
        Key: objectKey,
        Body: fileContent,
      })
    );
    console.log(`✓ File '${filePath}' uploaded as '${objectKey}'`);
  } catch (error) {
    console.error('Error uploading file:', error.message);
  }
}

/**
 * List all objects in a bucket
 */
async function listObjects(bucketName) {
  try {
    const response = await s3Client.send(
      new ListObjectsV2Command({ Bucket: bucketName })
    );

    if (!response.Contents || response.Contents.length === 0) {
      console.log(`📭 Bucket '${bucketName}' is empty`);
      return [];
    }

    console.log(`\n📄 Objects in '${bucketName}':`);
    response.Contents.forEach((obj) => {
      const sizeKB = (obj.Size / 1024).toFixed(2);
      console.log(`  - ${obj.Key} (${sizeKB} KB)`);
    });

    return response.Contents;
  } catch (error) {
    console.error('Error listing objects:', error.message);
    return [];
  }
}

/**
 * Download a file from S3 bucket
 */
async function downloadFile(bucketName, objectKey, localPath) {
  try {
    const response = await s3Client.send(
      new GetObjectCommand({
        Bucket: bucketName,
        Key: objectKey,
      })
    );

    const stream = response.Body;
    const writeStream = fs.createWriteStream(localPath);

    stream.pipe(writeStream);

    await new Promise((resolve, reject) => {
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });

    console.log(`✓ File '${objectKey}' downloaded to '${localPath}'`);
  } catch (error) {
    console.error('Error downloading file:', error.message);
  }
}

/**
 * Delete an object from S3 bucket
 */
async function deleteObject(bucketName, objectKey) {
  try {
    await s3Client.send(
      new DeleteObjectCommand({
        Bucket: bucketName,
        Key: objectKey,
      })
    );
    console.log(`✓ Object '${objectKey}' deleted`);
  } catch (error) {
    console.error('Error deleting object:', error.message);
  }
}

/**
 * Main function demonstrating S3 operations
 */
async function main() {
  console.log('='.repeat(60));
  console.log('AWS S3 Simulator - Node.js Example (AWS SDK v3)');
  console.log('='.repeat(60));

  try {
    // List existing buckets
    await listBuckets();

    // Create a test bucket
    const testBucket = 'nodejs-test-bucket';
    await createBucket(testBucket);

    // Create a sample file
    const sampleFile = 'test_file.txt';
    const content = [
      'Hello from AWS S3 Simulator!',
      'This is a test file created by Node.js example.',
    ].join('\n');
    fs.writeFileSync(sampleFile, content);

    // Upload file
    await uploadFile(testBucket, sampleFile, sampleFile);

    // List objects in bucket
    await listObjects(testBucket);

    // Download file
    const downloadPath = 'downloaded_file.txt';
    await downloadFile(testBucket, sampleFile, downloadPath);

    // Clean up local files
    if (fs.existsSync(sampleFile)) {
      fs.unlinkSync(sampleFile);
    }
    if (fs.existsSync(downloadPath)) {
      fs.unlinkSync(downloadPath);
    }

    console.log('\n' + '='.repeat(60));
    console.log('✓ Example completed successfully!');
    console.log('='.repeat(60));
  } catch (error) {
    console.error('Error in main:', error);
    process.exit(1);
  }
}

// Run the example
main();