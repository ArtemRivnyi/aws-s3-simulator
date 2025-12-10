import os
from flask import Flask, jsonify, render_template, request
from flask_restx import Api, Resource, fields
from prometheus_flask_exporter import PrometheusMetrics
from werkzeug.exceptions import BadRequest, NotFound
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['FLASK_ENV'] = os.getenv('FLASK_ENV', 'development')

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

# API Models for Swagger
bucket_model = api.model('Bucket', {
    'bucket_name': fields.String(required=True, description='Bucket name', example='my-test-bucket')
})

bucket_response = api.model('BucketResponse', {
    'buckets': fields.List(fields.String, description='List of bucket names')
})

# Mock mode flag
MOCK_MODE = os.getenv('MOCK_MODE', 'false').lower() == 'true'
MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT', 'http://localhost:9000')

# S3 Client wrapper
class S3Client:
    def __init__(self):
        self.mock_mode = MOCK_MODE
        self.mock_buckets = ['demo-bucket', 'test-bucket']
        
        if not self.mock_mode:
            try:
                import boto3
                from botocore.exceptions import ClientError
                
                self.client = boto3.client(
                    's3',
                    endpoint_url=MINIO_ENDPOINT,
                    aws_access_key_id=os.getenv('MINIO_ACCESS_KEY', 'admin'),
                    aws_secret_access_key=os.getenv('MINIO_SECRET_KEY', 'password123'),
                    region_name='us-east-1'
                )
                logger.info(f"S3 Client initialized with MinIO at {MINIO_ENDPOINT}")
            except Exception as e:
                logger.warning(f"Failed to connect to MinIO: {e}. Falling back to mock mode.")
                self.mock_mode = True
        else:
            logger.info("Running in MOCK mode - no real MinIO connection")
    
    def list_buckets(self):
        """List all buckets"""
        if self.mock_mode:
            return {'buckets': self.mock_buckets, 'mode': 'mock'}
        
        try:
            response = self.client.list_buckets()
            bucket_names = [b['Name'] for b in response.get('Buckets', [])]
            return {'buckets': bucket_names, 'mode': 'live'}
        except Exception as e:
            logger.error(f"Error listing buckets: {e}")
            return {'error': str(e), 'buckets': []}
    
    def create_bucket(self, bucket_name):
        """Create a new bucket"""
        if self.mock_mode:
            if bucket_name not in self.mock_buckets:
                self.mock_buckets.append(bucket_name)
            return {'success': True, 'bucket': bucket_name, 'mode': 'mock'}
        
        try:
            self.client.create_bucket(Bucket=bucket_name)
            return {'success': True, 'bucket': bucket_name, 'mode': 'live'}
        except Exception as e:
            logger.error(f"Error creating bucket {bucket_name}: {e}")
            return {'success': False, 'error': str(e)}
    
    def delete_bucket(self, bucket_name):
        """Delete a bucket"""
        if self.mock_mode:
            if bucket_name in self.mock_buckets:
                self.mock_buckets.remove(bucket_name)
            return {'success': True, 'bucket': bucket_name, 'mode': 'mock'}
        
        try:
            self.client.delete_bucket(Bucket=bucket_name)
            return {'success': True, 'bucket': bucket_name, 'mode': 'live'}
        except Exception as e:
            logger.error(f"Error deleting bucket {bucket_name}: {e}")
            return {'success': False, 'error': str(e)}
    
    def list_objects(self, bucket_name):
        """List objects in bucket"""
        if self.mock_mode:
            return {
                'objects': ['sample-file-1.txt', 'sample-file-2.jpg'],
                'bucket': bucket_name,
                'mode': 'mock'
            }
        
        try:
            response = self.client.list_objects_v2(Bucket=bucket_name)
            objects = [obj['Key'] for obj in response.get('Contents', [])]
            return {'objects': objects, 'bucket': bucket_name, 'mode': 'live'}
        except Exception as e:
            logger.error(f"Error listing objects in {bucket_name}: {e}")
            return {'error': str(e), 'objects': []}

# Initialize S3 client
s3_client = S3Client()

# Routes
@app.route('/')
def index():
    """Main page"""
    return render_template('index.html') if os.path.exists('templates/index.html') else jsonify({
        'message': 'AWS S3 Simulator API',
        'version': '1.0.0',
        'mode': 'mock' if MOCK_MODE else 'live',
        'endpoints': {
            'health': '/health',
            'api_docs': '/docs/',
            'metrics': '/metrics',
            'buckets': '/api/v1/buckets'
        }
    })

@app.route('/health')
def health():
    """Basic health check"""
    return jsonify({
        'status': 'healthy',
        'service': 'aws-s3-simulator',
        'mode': 'mock' if s3_client.mock_mode else 'live',
        'minio_endpoint': MINIO_ENDPOINT if not s3_client.mock_mode else 'N/A'
    }), 200

# API Endpoints
@ns_buckets.route('/')
class BucketList(Resource):
    @ns_buckets.doc('list_buckets')
    @ns_buckets.marshal_with(bucket_response)
    def get(self):
        """List all S3 buckets"""
        result = s3_client.list_buckets()
        return result, 200
    
    @ns_buckets.doc('create_bucket')
    @ns_buckets.expect(bucket_model)
    def post(self):
        """Create a new bucket"""
        data = request.get_json()
        bucket_name = data.get('bucket_name')
        
        if not bucket_name:
            return {'error': 'bucket_name is required'}, 400
        
        result = s3_client.create_bucket(bucket_name)
        return result, 201 if result.get('success') else 400

@ns_buckets.route('/<string:bucket_name>')
class Bucket(Resource):
    @ns_buckets.doc('delete_bucket')
    def delete(self, bucket_name):
        """Delete a bucket"""
        result = s3_client.delete_bucket(bucket_name)
        return result, 200 if result.get('success') else 400

@ns_buckets.route('/<string:bucket_name>/objects')
class ObjectList(Resource):
    @ns_buckets.doc('list_objects')
    def get(self, bucket_name):
        """List objects in bucket"""
        result = s3_client.list_objects(bucket_name)
        return result, 200

@ns_health.route('/')
class HealthDetailed(Resource):
    @ns_health.doc('health_detailed')
    def get(self):
        """Detailed health check with component status"""
        minio_status = 'healthy' if not s3_client.mock_mode else 'mock'
        
        return {
            'status': 'healthy',
            'service': 'aws-s3-simulator',
            'version': '1.0.0',
            'components': {
                'api': 'healthy',
                'minio': minio_status,
                'mode': 'mock' if s3_client.mock_mode else 'live'
            },
            'timestamp': os.popen('date -u +"%Y-%m-%dT%H:%M:%SZ"').read().strip()
        }, 200

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found', 'message': str(error)}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error', 'message': str(error)}), 500

@app.errorhandler(BadRequest)
def bad_request(error):
    return jsonify({'error': 'Bad request', 'message': str(error)}), 400

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    logger.info(f"Starting AWS S3 Simulator on port {port}")
    logger.info(f"Mode: {'MOCK' if s3_client.mock_mode else 'LIVE'}")
    logger.info(f"Debug: {debug}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)