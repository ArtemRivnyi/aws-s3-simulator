import os
import json
import logging
from datetime import datetime
from flask import Flask, jsonify, render_template, request, send_file
from flask_restx import Api, Resource, fields
from prometheus_flask_exporter import PrometheusMetrics
from werkzeug.exceptions import BadRequest, NotFound
from werkzeug.utils import secure_filename
from minio import Minio
from minio.error import S3Error

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['FLASK_ENV'] = os.getenv('FLASK_ENV', 'development')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max upload

# Prometheus metrics
metrics = PrometheusMetrics(app)

# Flask-RESTX API documentation
api = Api(
    app,
    version='1.0',
    title='AWS S3 Simulator API',
    description='MinIO-powered S3-compatible local storage API',
    doc='/docs/',
    prefix='/api/v1'
)

# Namespaces
ns_buckets = api.namespace('buckets', description='Bucket operations')
ns_health = api.namespace('health', description='Health checks')
ns_upload = api.namespace('upload', description='File upload operations')
ns_stats = api.namespace('stats', description='Usage statistics')

# API Models
bucket_model = api.model('Bucket', {
    'bucket_name': fields.String(required=True, description='Bucket name', example='my-test-bucket')
})

bucket_response = api.model('BucketResponse', {
    'buckets': fields.List(fields.String, description='List of bucket names')
})

# MinIO Configuration
MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT', 'localhost:9000')
MINIO_ACCESS_KEY = os.getenv('MINIO_ROOT_USER', 'minioadmin')
MINIO_SECRET_KEY = os.getenv('MINIO_ROOT_PASSWORD', 'minioadmin')
SECURE = os.getenv('MINIO_SECURE', 'false').lower() == 'true'

# S3 Client wrapper using MinIO SDK
class S3Client:
    def __init__(self):
        self.client = None
        self.connected = False
        self.connect()

    def connect(self):
        try:
            # Clean up endpoint for MinIO client (remove http:// or https://)
            endpoint = MINIO_ENDPOINT.replace('http://', '').replace('https://', '')
            
            self.client = Minio(
                endpoint,
                access_key=MINIO_ACCESS_KEY,
                secret_key=MINIO_SECRET_KEY,
                secure=SECURE
            )
            # Test connection
            self.client.list_buckets()
            self.connected = True
            logger.info(f"Successfully connected to MinIO at {endpoint}")
        except Exception as e:
            logger.error(f"Failed to connect to MinIO: {e}")
            self.connected = False

    def list_buckets(self):
        if not self.connected: self.connect()
        if not self.connected: return {'error': 'Not connected to MinIO', 'buckets': []}
        
        try:
            buckets = self.client.list_buckets()
            return {'buckets': [b.name for b in buckets], 'mode': 'live'}
        except Exception as e:
            logger.error(f"Error listing buckets: {e}")
            return {'error': str(e), 'buckets': []}

    def create_bucket(self, bucket_name):
        if not self.connected: self.connect()
        if not self.connected: return {'success': False, 'error': 'Not connected to MinIO'}

        try:
            if not self.client.bucket_exists(bucket_name):
                self.client.make_bucket(bucket_name)
                return {'success': True, 'bucket': bucket_name}
            return {'success': False, 'error': 'Bucket already exists'}
        except Exception as e:
            logger.error(f"Error creating bucket {bucket_name}: {e}")
            return {'success': False, 'error': str(e)}

    def delete_bucket(self, bucket_name):
        if not self.connected: self.connect()
        
        try:
            self.client.remove_bucket(bucket_name)
            return {'success': True, 'bucket': bucket_name}
        except Exception as e:
            logger.error(f"Error deleting bucket {bucket_name}: {e}")
            return {'success': False, 'error': str(e)}

    def list_objects(self, bucket_name):
        if not self.connected: self.connect()
        
        try:
            objects = self.client.list_objects(bucket_name)
            obj_list = []
            for obj in objects:
                obj_list.append({
                    'name': obj.object_name,
                    'size': obj.size,
                    'last_modified': obj.last_modified.isoformat() if obj.last_modified else None
                })
            return {'objects': obj_list, 'bucket': bucket_name}
        except Exception as e:
            logger.error(f"Error listing objects in {bucket_name}: {e}")
            return {'error': str(e), 'objects': []}

    def upload_file(self, bucket_name, file_obj, object_name, length):
        if not self.connected: self.connect()
        
        try:
            # Ensure bucket exists
            if not self.client.bucket_exists(bucket_name):
                self.client.make_bucket(bucket_name)
            
            self.client.put_object(
                bucket_name,
                object_name,
                file_obj,
                length
            )
            return {'success': True, 'bucket': bucket_name, 'object': object_name}
        except Exception as e:
            logger.error(f"Error uploading file: {e}")
            return {'success': False, 'error': str(e)}

    def get_stats(self):
        if not self.connected: self.connect()
        
        try:
            buckets = self.client.list_buckets()
            total_buckets = len(buckets)
            total_objects = 0
            total_size = 0
            
            for b in buckets:
                objects = self.client.list_objects(b.name, recursive=True)
                for obj in objects:
                    total_objects += 1
                    total_size += obj.size
            
            return {
                'buckets': total_buckets,
                'objects': total_objects,
                'storage_used_bytes': total_size,
                'status': 'healthy' if self.connected else 'unhealthy'
            }
        except Exception as e:
            logger.error(f"Error getting stats: {e}")
            return {'error': str(e)}

s3_client = S3Client()

# Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health')
def health():
    """Basic health check for Render"""
    # Check if MinIO is reachable
    s3_client.list_buckets()
    status = 'healthy' if s3_client.connected else 'degraded'
    return jsonify({
        'status': status,
        'service': 'aws-s3-simulator',
        'minio_connected': s3_client.connected
    }), 200 if status == 'healthy' else 503

# API Endpoints
@ns_buckets.route('/')
class BucketList(Resource):
    @ns_buckets.doc('list_buckets')
    def get(self):
        return s3_client.list_buckets()
    
    @ns_buckets.doc('create_bucket')
    @ns_buckets.expect(bucket_model)
    def post(self):
        data = request.get_json()
        bucket_name = data.get('bucket_name')
        if not bucket_name:
            return {'error': 'bucket_name is required'}, 400
        return s3_client.create_bucket(bucket_name)

@ns_buckets.route('/<string:bucket_name>')
class Bucket(Resource):
    @ns_buckets.doc('delete_bucket')
    def delete(self, bucket_name):
        return s3_client.delete_bucket(bucket_name)

@ns_buckets.route('/<string:bucket_name>/objects')
class ObjectList(Resource):
    @ns_buckets.doc('list_objects')
    def get(self, bucket_name):
        return s3_client.list_objects(bucket_name)

@ns_upload.route('/')
class Upload(Resource):
    @ns_upload.doc('upload_file')
    def post(self):
        if 'file' not in request.files:
            return {'error': 'No file part'}, 400
        file = request.files['file']
        if file.filename == '':
            return {'error': 'No selected file'}, 400
        
        bucket_name = request.form.get('bucket', 'default')
        object_name = secure_filename(file.filename)
        
        # Get file size
        file.seek(0, os.SEEK_END)
        size = file.tell()
        file.seek(0)
        
        return s3_client.upload_file(bucket_name, file, object_name, size)

@ns_stats.route('/')
class Stats(Resource):
    @ns_stats.doc('get_stats')
    def get(self):
        return s3_client.get_stats()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port)