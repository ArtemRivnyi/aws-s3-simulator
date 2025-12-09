from flask import Flask, send_from_directory
from prometheus_flask_exporter import PrometheusMetrics
from .routes import api_bp
import os

def create_app():
    # Configure to serve static files from 'api/static'
    app = Flask(__name__, static_url_path='/static', static_folder='static')
    
    # Initialize Prometheus metrics
    metrics = PrometheusMetrics(app)
    metrics.info('app_info', 'Application info', version='1.0.0')

    # Register Blueprints
    app.register_blueprint(api_bp)

    @app.route('/')
    def index():
        return send_from_directory(app.static_folder, 'index.html')

    @app.route('/health')
    def health():
        return {'status': 'up'}

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000)
