import sys
import os

# Add the local packages to path so we can import pyzipper
sys.path.append(os.path.join(os.getcwd(), 'python/lib/python3.14/site-packages'))

try:
    import pyzipper
except ImportError:
    print("Error: pyzipper not found in python/lib/python3.14/site-packages")
    sys.exit(1)

def create_aes_zip(filename, password):
    output_zip = 'notes_aes.zip'
    
    print(f"Creating {output_zip} with AES-256 encryption...")
    
    with pyzipper.AESZipFile(output_zip,
                             'w',
                             compression=pyzipper.ZIP_DEFLATED,
                             encryption=pyzipper.WZ_AES) as zf:
        zf.setpassword(password.encode('utf-8'))
        zf.write(filename)
        
    print(f"Successfully created {output_zip}")

if __name__ == "__main__":
    create_aes_zip('test', 'Passw0rd!')
