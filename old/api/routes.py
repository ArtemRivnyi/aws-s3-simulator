from flask import Blueprint, request, jsonify, send_file
from flask_restx import Api, Resource, fields
from werkzeug.datastructures import FileStorage
from .s3_client import S3Client
import io

api_bp = Blueprint('api', __name__, url_prefix='/api/v1')
api = Api(api_bp, version='1.0', title='AWS S3 Simulator API',
          description='A simple S3 compatible API')

ns = api.namespace('s3', description='S3 operations')

s3 = S3Client()

bucket_model = api.model('Bucket', {
    'name': fields.String(required=True, description='The bucket name')
})

upload_parser = api.parser()
upload_parser.add_argument('file', location='files',
                           type=FileStorage, required=True)

@ns.route('/buckets')
class BucketList(Resource):
    def get(self):
        """List all buckets"""
        try:
            buckets = s3.list_buckets()
            return jsonify(buckets)
        except Exception as e:
            return {'error': str(e)}, 500

    @api.expect(bucket_model)
    def post(self):
        """Create a new bucket"""
        data = request.json
        try:
            s3.create_bucket(data['name'])
            return {'message': f"Bucket {data['name']} created successfully"}, 201
        except Exception as e:
            return {'error': str(e)}, 500

@ns.route('/buckets/<string:bucket_name>')
class Bucket(Resource):
    def delete(self, bucket_name):
        """Delete a bucket"""
        try:
            s3.delete_bucket(bucket_name)
            return {'message': f"Bucket {bucket_name} deleted successfully"}, 200
        except Exception as e:
            return {'error': str(e)}, 500

@ns.route('/buckets/<string:bucket_name>/objects')
class ObjectList(Resource):
    def get(self, bucket_name):
        """List objects in a bucket"""
        try:
            objects = s3.list_objects(bucket_name)
            return jsonify(objects)
        except Exception as e:
            return {'error': str(e)}, 500

    @api.expect(upload_parser)
    def post(self, bucket_name):
        """Upload an object to a bucket"""
        args = upload_parser.parse_args()
        uploaded_file = args['file']
        try:
            s3.upload_file(uploaded_file, bucket_name, uploaded_file.filename)
            return {'message': f"File {uploaded_file.filename} uploaded successfully"}, 201
        except Exception as e:
            return {'error': str(e)}, 500

@ns.route('/buckets/<string:bucket_name>/objects/<path:object_name>')
class Object(Resource):
    def get(self, bucket_name, object_name):
        """Download an object"""
        try:
            file_obj = s3.download_file(bucket_name, object_name)
            return send_file(
                io.BytesIO(file_obj.read()),
                as_attachment=True,
                download_name=object_name.split('/')[-1]
            )
        except Exception as e:
            return {'error': str(e)}, 500

    def delete(self, bucket_name, object_name):
        """Delete an object"""
        try:
            s3.delete_object(bucket_name, object_name)
            return {'message': f"Object {object_name} deleted successfully"}, 200
        except Exception as e:
            return {'error': str(e)}, 500

@ns.route('/health')
class Health(Resource):
    def get(self):
        """Health check"""
        try:
            s3.list_buckets()
            return {'status': 'healthy', 'service': 's3-api'}, 200
        except Exception as e:
            return {'status': 'unhealthy', 'error': str(e)}, 503
