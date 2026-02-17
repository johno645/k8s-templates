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


def unzip_file(zip_data, password):
    """
    Extract AES-256 or ZipCrypto password-protected zip file using pyzipper.
    pyzipper supports:
      - AES-128
      - AES-192
      - AES-256
      - Legacy ZipCrypto (fallback)
    """
    extracted_files = {}

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
                extracted_files[filename] = file_content
                print(f"Extracted: {filename} ({len(file_content)} bytes)")

    except RuntimeError as e:
        if 'Bad password' in str(e):
            raise ValueError("Incorrect password for zip file")
        raise
    except pyzipper.BadZipFile as e:
        print(f"Invalid zip file: {e}")
        raise

    return extracted_files


def lambda_handler(event, context):
    """
    Lambda handler.

    Expected event:
    {
        "source_bucket": "my-bucket",
        "source_key": "path/to/encrypted.zip",
        "secret_name": "my-zip​​​​​​​​​​​​​​​​
