import sys
import os

# Add the local packages to path so we can import pyzipper
sys.path.append(os.path.join(os.getcwd(), 'python/lib/python3.14/site-packages'))

try:
    import pyzipper
except ImportError:
    print("Error: pyzipper not found in python/lib/python3.14/site-packages")
    sys.exit(1)

def create_aes_zip(target_path, password):
    output_zip = 'encrypted.zip'
    
    print(f"Creating {output_zip} with AES-256 encryption...")
    
    with pyzipper.AESZipFile(output_zip,
                             'w',
                             compression=pyzipper.ZIP_DEFLATED,
                             encryption=pyzipper.WZ_AES) as zf:
        zf.setpassword(password.encode('utf-8'))
        
        if os.path.isdir(target_path):
            # Recursively zip directory contents
            for root, dirs, files in os.walk(target_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, os.path.dirname(target_path))
                    print(f"Adding {arcname}...")
                    zf.write(file_path, arcname)
        else:
            # Just zip the single file
            zf.write(target_path)
        
    print(f"Successfully created {output_zip}")

if __name__ == "__main__":
    create_aes_zip('test', 'Passw0rd!')
