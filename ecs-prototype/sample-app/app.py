import os
import boto3
from flask import Flask, jsonify
from botocore.exceptions import ClientError

app = Flask(__name__)

# Configure AWS clients to use LocalStack
endpoint_url = os.getenv('AWS_ENDPOINT_URL', 'http://localstack:4566')
region = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')

ssm_client = boto3.client(
    'ssm',
    endpoint_url=endpoint_url,
    region_name=region,
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID', 'test'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY', 'test')
)

secrets_client = boto3.client(
    'secretsmanager',
    endpoint_url=endpoint_url,
    region_name=region,
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID', 'test'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY', 'test')
)


@app.route('/health')
def health():
    """Health check endpoint for load balancer"""
    return jsonify({"status": "healthy"}), 200


@app.route('/')
def index():
    """Main endpoint"""
    return jsonify({
        "message": "Hello from ECS prototype!",
        "environment": "local-development",
        "endpoints": {
            "/health": "Health check",
            "/config": "Get configuration from Parameter Store",
            "/secret": "Get secret from Secrets Manager",
            "/info": "Get environment info"
        }
    }), 200


@app.route('/config')
def get_config():
    """Retrieve configuration from SSM Parameter Store"""
    try:
        # Try to get a parameter
        response = ssm_client.get_parameter(
            Name='/myapp/config/environment',
            WithDecryption=True
        )
        return jsonify({
            "source": "SSM Parameter Store",
            "parameter": response['Parameter']['Name'],
            "value": response['Parameter']['Value'],
            "type": response['Parameter']['Type']
        }), 200
    except ClientError as e:
        return jsonify({
            "error": "Parameter not found or error accessing SSM",
            "details": str(e),
            "note": "Make sure LocalStack initialization has run"
        }), 404


@app.route('/secret')
def get_secret():
    """Retrieve secret from Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(
            SecretId='myapp/database/password'
        )
        return jsonify({
            "source": "Secrets Manager",
            "secret_name": response['Name'],
            "secret_value": response['SecretString'],
            "note": "In production, never expose secrets like this!"
        }), 200
    except ClientError as e:
        return jsonify({
            "error": "Secret not found or error accessing Secrets Manager",
            "details": str(e),
            "note": "Make sure LocalStack initialization has run"
        }), 404


@app.route('/info')
def info():
    """Get environment information"""
    return jsonify({
        "aws_region": region,
        "aws_endpoint": endpoint_url,
        "environment_variables": {
            k: v for k, v in os.environ.items()
            if k.startswith(('AWS_', 'LOCALSTACK_'))
        }
    }), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
