const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

class S3SimulatorClient {
    constructor(baseUrl = 'http://localhost:5000/api/v1/s3') {
        this.client = axios.create({
            baseURL: baseUrl
        });
    }

    async listBuckets() {
        const response = await this.client.get('/buckets');
        return response.data;
    }

    async createBucket(bucketName) {
        const response = await this.client.post('/buckets', { name: bucketName });
        return response.data;
    }

    async deleteBucket(bucketName) {
        const response = await this.client.delete(`/buckets/${bucketName}`);
        return response.data;
    }

    async listObjects(bucketName) {
        const response = await this.client.get(`/buckets/${bucketName}/objects`);
        return response.data;
    }

    async uploadFile(bucketName, filePath, objectName) {
        const form = new FormData();
        const fileStream = fs.createReadStream(filePath);
        const fileName = objectName || filePath.split('/').pop();

        form.append('file', fileStream, fileName);

        const response = await this.client.post(`/buckets/${bucketName}/objects`, form, {
            headers: {
                ...form.getHeaders()
            }
        });
        return response.data;
    }

    async downloadFile(bucketName, objectName, downloadPath) {
        const response = await this.client.get(`/buckets/${bucketName}/objects/${objectName}`, {
            responseType: 'stream'
        });

        const writer = fs.createWriteStream(downloadPath);
        response.data.pipe(writer);

        return new Promise((resolve, reject) => {
            writer.on('finish', resolve);
            writer.on('error', reject);
        });
    }

    async deleteObject(bucketName, objectName) {
        const response = await this.client.delete(`/buckets/${bucketName}/objects/${objectName}`);
        return response.data;
    }
}

module.exports = S3SimulatorClient;
