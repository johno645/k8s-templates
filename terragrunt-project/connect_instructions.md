# Connecting to Rocky Linux EC2 via VS Code & SSM

## Prerequisites

1.  **AWS CLI**: Installed and configured (`aws configure`).
2.  **Session Manager Plugin**: Installed on your local machine.
    *   [Install Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
3.  **VS Code**: Installed with the **Remote - SSH** extension.

## 1. SSH Config Setup

Add the following to your local `~/.ssh/config` file. This tells SSH to use the AWS SSM plugin as a proxy command.

```ssh
# Generic entry for any instance ID
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
    User rocky
    IdentityFile ~/.ssh/id_rsa
    # StrictHostKeyChecking no # Optional: useful if instance IDs change often
```

*Note: The `IdentityFile` is strictly not required if we are using password auth, but SSH client might complain if it's missing. You can ignore key warnings.*

## 2. Connect via VS Code

1.  Open VS Code.
2.  Press `F1` (or `Ctrl+Shift+P` / `Cmd+Shift+P`) to open the command palette.
3.  Type **Remote-SSH: Connect to Host...**.
4.  Enter the **Instance ID** of your Rocky Linux server (e.g., `i-0123456789abcdef0`).
    *   *Tip: You can find this in the AWS Console.*
5.  VS Code will start the connection.
6.  When prompted for the password, enter the password set in the setup script (Default: `RockyDev2025!` unless you changed it).

## 3. Troubleshooting

*   **Permission Denied**: Ensure your IAM user/role locally has `ssm:StartSession` permission.
*   **Instance Not Found**: Ensure the EC2 instance has an IAM Role attached with the `AmazonSSMManagedInstanceCore` policy.
*   **SSM Agent**: Verify the SSM agent is running on the instance (`systemctl status amazon-ssm-agent`).
