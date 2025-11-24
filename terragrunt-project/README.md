# Terragrunt Multi-State Project

This project demonstrates a Terragrunt setup that manages **3 separate Terraform state files** in GitLab, using:
- **AWS Provider** for network and application infrastructure
- **Kubernetes Provider** for database deployment
- **GitLab HTTP Backend** for state management

## Project Structure

```
terragrunt-project/
├── root.hcl                # Root configuration (GitLab backend + AWS provider)
├── set-env.sh              # Interactive environment setup script
├── dev/
│   ├── env.hcl             # Environment-specific variables for dev
│   ├── env.hcl.example     # Example environment configuration
│   ├── network/
│   │   └── terragrunt.hcl  # State file 1: AWS VPC infrastructure
│   ├── database/
│   │   └── terragrunt.hcl  # State file 2: Kubernetes PostgreSQL
│   └── application/
│       └── terragrunt.hcl  # State file 3: AWS Application (ALB + ASG)
└── modules/
    ├── network/            # AWS VPC, subnets, IGW
    ├── database/           # Kubernetes PostgreSQL deployment
    │   └── provider.tf     # Kubernetes provider override
    └── application/        # AWS ALB, ASG, EC2 launch template
```

## Components

1. **Network** (AWS): VPC, public subnets, Internet Gateway, route tables
2. **Database** (Kubernetes): PostgreSQL deployment with persistent storage
3. **Application** (AWS): Auto Scaling Group, Application Load Balancer, EC2 instances

## Prerequisites

### Required Tools
- [Terragrunt](https://terragrunt.gruntwork.io/) >= 0.45.0
- [Terraform](https://www.terraform.io/) >= 1.0
- AWS CLI configured with credentials
- kubectl configured with access to your Kubernetes cluster

### Environment Configuration

1. **Create environment configuration file**:
   ```bash
   cd dev
   cp env.hcl.example env.hcl
   # Edit env.hcl with your environment-specific values
   ```

2. **Set required environment variables**:
   ```bash
   # GitLab State Management
   export GITLAB_PROJECT_ID="your-gitlab-project-id"
   export GITLAB_USERNAME="your-gitlab-username"
   export GITLAB_ACCESS_TOKEN="your-gitlab-access-token"

   # AWS Configuration
   export AWS_ACCESS_KEY_ID="your-aws-access-key"
   export AWS_SECRET_ACCESS_KEY="your-aws-secret-key"

   # Application Configuration
   export AMI_ID="ami-xxxxxxxxx"  # Amazon Linux 2 AMI for your region

   # Database Credentials
   export DB_USER="postgres"
   export DB_PASSWORD="your-secure-password"

   # Kubernetes Configuration
   export KUBECONFIG="~/.kube/config"  # Path to your kubeconfig
   ```

> [!NOTE]
> Most configuration values are now in `dev/env.hcl` instead of being hardcoded. This makes it easy to create additional environments (staging, prod) by copying the dev directory and customizing `env.hcl`.

## Quick Start

### 1. Set Your Environment
Use the interactive setup script to select your deployment environment:

```bash
# Source the script to export variables to your current shell
source ./set-env.sh
```

The script will:
- Prompt you to select dev, staging, or prod
- Set the `DEPLOY_ENV` environment variable
- Validate that required environment variables are configured
- Show you the next steps

### 2. Navigate to Environment Directory
```bash
cd $DEPLOY_ENV  # or cd dev, cd staging, cd prod
```

## Usage

### Initialize all components
```bash
cd dev
terragrunt run-all init
```

### Plan all components
```bash
cd dev
terragrunt run-all plan
```

### Apply all components (respects dependencies)
```bash
cd dev
terragrunt run-all apply
```

### Apply individual component
```bash
# Network first
cd dev/network
terragrunt apply

# Then database
cd ../database
terragrunt apply

# Finally application
cd ../application
terragrunt apply
```

### Destroy all components
```bash
cd dev
terragrunt run-all destroy
```

## State Files in GitLab

Each component maintains its own Terraform state file in GitLab:

- **Network**: `https://gitlab.com/api/v4/projects/{project_id}/terraform/state/dev/network`
- **Database**: `https://gitlab.com/api/v4/projects/{project_id}/terraform/state/dev/database`
- **Application**: `https://gitlab.com/api/v4/projects/{project_id}/terraform/state/dev/application`

State locking is handled automatically via GitLab's HTTP backend.

## Dependencies

The components have the following dependencies:

```
network (AWS VPC)
  ├── database (Kubernetes) - uses network name in tags
  └── application (AWS) - deploys into VPC subnets
      └── database - connects to database endpoint
```

Terragrunt automatically handles the dependency order during `run-all` operations.

## Provider Configuration

### Network & Application
Uses AWS provider configured in root `root.hcl`:
- Region: Configurable via `AWS_REGION` env var (default: us-east-1)
- Default tags applied to all resources

### Database
Uses Kubernetes provider (overrides AWS):
- Configured via `modules/database/provider.tf`
- Connects using kubeconfig or environment variables
- Deploys PostgreSQL to Kubernetes cluster

## Security Notes

> [!WARNING]
> - Never commit sensitive values (passwords, tokens) to version control
> - Use environment variables or a secrets manager for credentials
> - The database password is passed via `DB_PASSWORD` env var
> - GitLab access token should have appropriate permissions for state management

## Customization

### Environment-Specific Configuration
All environment-specific values are centralized in `dev/env.hcl`:
- Network: VPC CIDR, subnet count
- Database: PostgreSQL version, storage size, resource limits
- Application: Instance type, ASG sizing, health check path, replica counts
- Tags: Common tags applied to all resources

To create a new environment (e.g., staging or prod):
1. Copy the `dev` directory: `cp -r dev staging`
2. Update `staging/env.hcl` with environment-specific values
3. Update the `environment` local variable in `env.hcl`

### Component-Specific Overrides
You can still override specific values in individual component `terragrunt.hcl` files if needed, but most configuration should be in `env.hcl` for consistency.
