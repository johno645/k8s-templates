#!/bin/bash
# User data script for application instances

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Set environment variables
export APP_NAME="${application_name}"
export APP_VERSION="${application_version}"
export DATABASE_ENDPOINT="${database_endpoint}"

# Pull and run application container (example)
# docker pull myapp:${application_version}
# docker run -d -p 80:8080 \
#   -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT \
#   myapp:${application_version}

# For demonstration, create a simple web server
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>${application_name}</title></head>
<body>
  <h1>${application_name} v${application_version}</h1>
  <p>Database: ${database_endpoint}</p>
</body>
</html>
EOF

echo "Application ${application_name} v${application_version} started successfully"
