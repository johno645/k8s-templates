import json
import boto3
import pyzipper  # replaces zipfile
import io
import os
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')
secrets_client = boto3.client('secretsmanager')


def get_secret(secret_name):
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in response:
            secret = response['SecretString']
            try:
                secret_dict = json.loads(secret)
                return secret_dict.get('password', secret)
            except json.JSONDecodeError:
                return secret
        else:
            return response['SecretBinary'].decode('utf-8')
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        raise


def download_from_s3(bucket, key):
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        return io.BytesIO(response['Body'].read())
    except ClientError as e:
        print(f"Error downloading from S3: {e}")
        raise


def upload_to_s3(bucket, key, data):
    try:
        s3_client.put_object(Bucket=bucket, Key=key, Body=data)
        print(f"Uploaded {key} to {bucket}")
    except ClientError as e:
        print(f"Error uploading to S3: {e}")
        raise


def detect_encryption_type(zip_data):
    """
    Attempt to detect whether the zip uses ZipCrypto or AES encryption.
    Useful for logging and debugging purposes.
    """
    zip_data.seek(0)
    try:
        # pyzipper can inspect the zip structure
        with pyzipper.AESZipFile(zip_data, 'r') as zf:
            for info in zf.infolist():
                # Compression type 99 = AES encrypted
                if info.compress_type == 99:
                    zip_data.seek(0)
                    return "AES-256"
        zip_data.seek(0)
        return "ZipCrypto"
    except Exception:
        zip_data.seek(0)
        return "Unknown"


def unzip_file_generator(zip_data, password):
    """
    Generator that yields (filename, content) for each file in the encrypted zip.
    This approach processes files one by one, reducing memory usage (conceptually
    'removing' contents from memory after each iteration).
    """
    try:
        encryption_type = detect_encryption_type(zip_data)
        print(f"Detected encryption type: {encryption_type}")
        zip_data.seek(0)

        with pyzipper.AESZipFile(zip_data, 'r') as zf:
            zf.setpassword(password.encode('utf-8'))
            file_list = zf.namelist()
            print(f"Files in archive: {file_list}")

            for filename in file_list:
                if filename.endswith('/'):
                    continue

                file_content = zf.read(filename)
                yield filename, file_content
                # Content is yielded and then discarded from this scope

    except RuntimeError as e:
        if 'Bad password' in str(e):
            raise ValueError("Incorrect password for zip file")
        raise
    except pyzipper.BadZipFile as e:
        print(f"Invalid zip file: {e}")
        raise


def lambda_handler(event, context):
    """
    Lambda handler.

    Expected event:
    {
        "source_bucket": "my-bucket",
        "source_key": "path/to/encrypted.zip",
        "secret_name": "my-zip-password",
        "destination_bucket": "my-output-bucket",   # optional
        "destination_prefix": "extracted/"           # optional
    }
    """
    try:
        source_bucket = event.get('source_bucket')
        source_key = event.get('source_key')
        secret_name = event.get('secret_name')
        destination_bucket = event.get('destination_bucket', source_bucket)
        destination_prefix = event.get('destination_prefix', '')

        if not all([source_bucket, source_key, secret_name]):
            raise ValueError("Missing required parameters: source_bucket, source_key, secret_name")

        print(f"Processing: s3://{source_bucket}/{source_key}")

        password = get_secret(secret_name)
        zip_data = download_from_s3(source_bucket, source_key)
        
        uploaded_files = []
        
        # Use generator to process files one by one
        # This ensures we don't hold all extracted files in memory ("removing" them as we go)
        for filename, content in unzip_file_generator(zip_data, password):
            if destination_prefix:
                destination_key = f"{destination_prefix.rstrip('/')}/{filename}"
            else:
                source_dir = os.path.dirname(source_key)
                destination_key = f"{source_dir}/{filename}" if source_dir else filename

            upload_to_s3(destination_bucket, destination_key, content)
            
            uploaded_files.append({
                'filename': filename,
                's3_location': f"s3://{destination_bucket}/{destination_key}",
                'size': len(content)
            })
            
        # Explicit cleanup
        del zip_data


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
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Validation error', 'message': str(e)})
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal error', 'message': str(e)})
        }
