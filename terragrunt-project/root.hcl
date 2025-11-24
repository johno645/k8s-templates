# Root Terragrunt Configuration
# This file contains common configuration that will be inherited by all child modules

locals {
  # GitLab configuration - UPDATE THESE VALUES
  gitlab_project_id = get_env("GITLAB_PROJECT_ID", "your-project-id")
  gitlab_username   = get_env("GITLAB_USERNAME", "your-username")
  gitlab_token      = get_env("GITLAB_ACCESS_TOKEN", "")
  
  # Detect environment from path (e.g., "dev", "staging", "prod")
  # Assumes structure like: /path/to/project/{environment}/{component}/terragrunt.hcl
  parsed_path  = split("/", path_relative_to_include())
  environment  = length(local.parsed_path) > 0 ? local.parsed_path[0] : "unknown"
  
  # For non-dev environments, include username in state path for isolation
  # This allows developers to have their own state for staging/prod testing
  state_path_prefix = local.environment == "dev" ? "" : "${local.gitlab_username}/"
  state_path        = "${local.state_path_prefix}${path_relative_to_include()}"
  
  # Common tags to apply to all AWS resources
  common_tags = {
    ManagedBy   = "Terragrunt"
    Environment = local.environment
    Project     = "terragrunt-demo"
  }
  
  # AWS configuration
  aws_region = get_env("AWS_REGION", "us-east-1")
}

# Generate GitLab HTTP backend configuration for state management
# Each component will have its own state file in GitLab
# Non-dev environments will include username in path for isolation
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${local.state_path}"
    lock_address   = "https://gitlab.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${local.state_path}/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${local.state_path}/lock"
    username       = "${local.gitlab_username}"
    password       = "${local.gitlab_token}"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
EOF
}

# Generate AWS provider configuration (default for network and application)
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}
