import boto3
from botocore.exceptions import ClientError
from .config import Config

class S3Client:
    def __init__(self):
        self.client = boto3.client(
            's3',
            endpoint_url=Config.AWS_ENDPOINT_URL,
            aws_access_key_id=Config.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=Config.AWS_SECRET_ACCESS_KEY,
            region_name=Config.AWS_REGION
        )

    def list_buckets(self):
        try:
            response = self.client.list_buckets()
            return response.get('Buckets', [])
        except ClientError as e:
            raise e

    def create_bucket(self, bucket_name):
        try:
            self.client.create_bucket(Bucket=bucket_name)
            return True
        except ClientError as e:
            raise e

    def delete_bucket(self, bucket_name):
        try:
            self.client.delete_bucket(Bucket=bucket_name)
            return True
        except ClientError as e:
            raise e

    def list_objects(self, bucket_name):
        try:
            response = self.client.list_objects_v2(Bucket=bucket_name)
            return response.get('Contents', [])
        except ClientError as e:
            raise e

    def upload_file(self, file_obj, bucket_name, object_name):
        try:
            self.client.upload_fileobj(file_obj, bucket_name, object_name)
            return True
        except ClientError as e:
            raise e

    def download_file(self, bucket_name, object_name):
        try:
            response = self.client.get_object(Bucket=bucket_name, Key=object_name)
            return response['Body']
        except ClientError as e:
            raise e

    def delete_object(self, bucket_name, object_name):
        try:
            self.client.delete_object(Bucket=bucket_name, Key=object_name)
            return True
        except ClientError as e:
            raise e

    def get_presigned_url(self, bucket_name, object_name, expiration=3600):
        try:
            response = self.client.generate_presigned_url('get_object',
                                                        Params={'Bucket': bucket_name,
                                                                'Key': object_name},
                                                        ExpiresIn=expiration)
            return response
        except ClientError as e:
            raise e
