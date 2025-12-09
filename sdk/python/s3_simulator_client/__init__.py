import requests
import os

class S3SimulatorClient:
    def __init__(self, base_url=None):
        self.base_url = base_url or os.environ.get('S3_SIMULATOR_URL', 'http://localhost:5000/api/v1/s3')

    def list_buckets(self):
        """List all buckets."""
        response = requests.get(f"{self.base_url}/buckets")
        response.raise_for_status()
        return response.json()

    def create_bucket(self, bucket_name):
        """Create a new bucket."""
        response = requests.post(f"{self.base_url}/buckets", json={'name': bucket_name})
        response.raise_for_status()
        return response.json()

    def delete_bucket(self, bucket_name):
        """Delete a bucket."""
        response = requests.delete(f"{self.base_url}/buckets/{bucket_name}")
        response.raise_for_status()
        return response.json()

    def list_objects(self, bucket_name):
        """List objects in a bucket."""
        response = requests.get(f"{self.base_url}/buckets/{bucket_name}/objects")
        response.raise_for_status()
        return response.json()

    def upload_file(self, bucket_name, file_path, object_name=None):
        """Upload a file to a bucket."""
        if object_name is None:
            object_name = os.path.basename(file_path)
            
        with open(file_path, 'rb') as f:
            files = {'file': (object_name, f)}
            response = requests.post(f"{self.base_url}/buckets/{bucket_name}/objects", files=files)
            
        response.raise_for_status()
        return response.json()

    def download_file(self, bucket_name, object_name, download_path):
        """Download a file from a bucket."""
        response = requests.get(f"{self.base_url}/buckets/{bucket_name}/objects/{object_name}", stream=True)
        response.raise_for_status()
        
        with open(download_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        return download_path

    def delete_object(self, bucket_name, object_name):
        """Delete an object from a bucket."""
        response = requests.delete(f"{self.base_url}/buckets/{bucket_name}/objects/{object_name}")
        response.raise_for_status()
        return response.json()
