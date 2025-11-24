#!/bin/bash
set -e

# Log output to a file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting setup for Rocky Linux VS Code / SSM..."

# 1. Update System
echo "Updating system packages..."
dnf update -y

# 2. Install Dependencies
# git is required for many VS Code extensions
# python3 is often needed
echo "Installing dependencies..."
dnf install -y git python3 policycoreutils-python-utils

# 3. Ensure SSM Agent is installed and running
echo "Checking SSM Agent..."
if ! systemctl is-active --quiet amazon-ssm-agent; then
    echo "Installing Amazon SSM Agent..."
    dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
else
    echo "SSM Agent is already running."
fi

# 4. Configure SSH for Password Authentication
# Cloud images usually disable password auth. We need to enable it.
echo "Configuring SSH for password authentication..."
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSHD to apply changes
systemctl restart sshd

# 5. Set User Password
# WARNING: It is highly recommended to change this password immediately after login.
# You can pass the password as the first argument to this script, or use the default.
USERNAME="rocky"
PASSWORD="${1:-RockyDev2025!}"

echo "Setting password for user $USERNAME..."
echo "$USERNAME:$PASSWORD" | chpasswd

echo "Setup complete!"
echo "User: $USERNAME"
echo "Password set. Please update it immediately."
