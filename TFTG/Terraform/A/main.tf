resource "local_file" "test" {
    content = "Hello, World! A"

    filename = "/Users/johnsidford/Documents/TFTG/testA.txt"
}

output "output" {
    value = "this-is-an-output-from-A"
}  



import json
import boto3
import zipfile
import io
import os
from botocore.exceptions import ClientError

# Initialize AWS clients
s3_client = boto3.client('s3')
secrets_client = boto3.client('secretsmanager')

def get_secret(secret_name):
    """
    Retrieve password from AWS Secrets Manager
    
    Args:
        secret_name: Name or ARN of the secret
        
    Returns:
        The secret value (password)
    """
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        
        # Secrets can be stored as string or binary
        if 'SecretString' in response:
            secret = response['SecretString']
            # If stored as JSON, parse it
            try:
                secret_dict = json.loads(secret)
                # Assume password is stored under 'password' key
                return secret_dict.get('password', secret)
            except json.JSONDecodeError:
                # If not JSON, return as-is
                return secret
        else:
            # Binary secret
            return response['SecretBinary'].decode('utf-8')
            
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        raise

def download_from_s3(bucket, key):
    """
    Download file from S3 into memory
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
        
    Returns:
        BytesIO object containing file data
    """
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        return io.BytesIO(response['Body'].read())
    except ClientError as e:
        print(f"Error downloading from S3: {e}")
        raise

def upload_to_s3(bucket, key, data):
    """
    Upload file to S3
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
        data: File data (bytes)
    """
    try:
        s3_client.put_object(Bucket=bucket, Key=key, Body=data)
        print(f"Uploaded {key} to {bucket}")
    except ClientError as e:
        print(f"Error uploading to S3: {e}")
        raise

def unzip_file(zip_data, password):
    """
    Extract password-protected zip file
    
    Args:
        zip_data: BytesIO object containing zip file
        password: Password string for the zip file
        
    Returns:
        Dictionary of {filename: file_content}
    """
    extracted_files = {}
    
    try:
        with zipfile.ZipFile(zip_data, 'r') as zip_ref:
            # List all files in the archive
            file_list = zip_ref.namelist()
            print(f"Files in archive: {file_list}")
            
            # Extract each file
            for filename in file_list:
                # Skip directories
                if filename.endswith('/'):
                    continue
                    
                # Extract with password (must be bytes)
                file_content = zip_ref.read(filename, pwd=password.encode('utf-8'))
                extracted_files[filename] = file_content
                print(f"Extracted: {filename} ({len(file_content)} bytes)")
                
    except RuntimeError as e:
        if 'Bad password' in str(e):
            print("Error: Incorrect password for zip file")
            raise ValueError("Incorrect password for zip file")
        else:
            raise
    except zipfile.BadZipFile as e:
        print(f"Error: Invalid zip file - {e}")
        raise
        
    return extracted_files

def lambda_handler(event, context):
    """
    Lambda handler function
    
    Expected event structure:
    {
        "source_bucket": "my-bucket",
        "source_key": "path/to/encrypted.zip",
        "secret_name": "my-zip-password",
        "destination_bucket": "my-output-bucket",  # Optional, defaults to source_bucket
        "destination_prefix": "extracted/"  # Optional, defaults to same directory as zip
    }
    """
    
    try:
        # Parse event parameters
        source_bucket = event.get('source_bucket')
        source_key = event.get('source_key')
        secret_name = event.get('secret_name')
        destination_bucket = event.get('destination_bucket', source_bucket)
        destination_prefix = event.get('destination_prefix', '')
        
        # Validate required parameters
        if not all([source_bucket, source_key, secret_name]):
            raise ValueError("Missing required parameters: source_bucket, source_key, secret_name")
        
        print(f"Processing zip file: s3://{source_bucket}/{source_key}")
        
        # Step 1: Retrieve password from Secrets Manager
        print(f"Retrieving password from secret: {secret_name}")
        password = get_secret(secret_name)
        
        # Step 2: Download zip file from S3
        print(f"Downloading zip file from S3...")
        zip_data = download_from_s3(source_bucket, source_key)
        
        # Step 3: Extract zip file with password
        print(f"Extracting zip file...")
        extracted_files = unzip_file(zip_data, password)
        
        # Step 4: Upload extracted files back to S3
        uploaded_files = []
        for filename, content in extracted_files.items():
            # Construct destination path
            if destination_prefix:
                destination_key = f"{destination_prefix.rstrip('/')}/{filename}"
            else:
                # Extract to same directory as source zip
                source_dir = os.path.dirname(source_key)
                destination_key = f"{source_dir}/{filename}" if source_dir else filename
            
            # Upload to S3
            upload_to_s3(destination_bucket, destination_key, content)
            uploaded_files.append({
                'filename': filename,
                's3_location': f"s3://{destination_bucket}/{destination_key}",
                'size': len(content)
            })
        
        # Return success response
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully extracted zip file',
                'source': f"s3://{source_bucket}/{source_key}",
                'files_extracted': len(uploaded_files),
                'files': uploaded_files
            })
        }
        
    except ValueError as e:
        print(f"Validation error: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Validation error',
                'message': str(e)
            })
        }
        
    except Exception as e:
        print(f"Error processing zip file: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal error',
                'message': str(e)
            })
        }
