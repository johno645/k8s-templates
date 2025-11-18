# Configure Terragrunt to use common settings for all its subfolders
locals {
  # Get environment from command line or default to dev
  # Usage: terragrunt run-all apply --terragrunt-var environment=prod
  environment        = get_env("TG_ENVIRONMENT", "dev")
  gitlab_project_id  = get_env("TG_GITLAB_PROJECT_ID", "")
}

# Configure GitLab as the backend
# State files are separated by environment and app:
# - dev/app1/terraform.tfstate
# - dev/app2/terraform.tfstate
# - prod/app1/terraform.tfstate
# - prod/app2/terraform.tfstate
remote_state {
  backend = "http"
  config = {
    # State path includes environment for clear separation
    address        = "https://gitlab.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${local.environment}/${path_relative_to_include()}"
    lock_address   = "https://gitlab.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${local.environment}/${path_relative_to_include()}/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${local.environment}/${path_relative_to_include()}/lock"
    username       = "terraform"
    password       = get_env("GITLAB_ACCESS_TOKEN", "")
    retry_wait_min = 5
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Add your provider configurations here
# Example for AWS:
# provider "aws" {
#   region = "us-east-1"
# }

# Example for GitLab:
# provider "gitlab" {
#   token = get_env("GITLAB_TOKEN", "")
# }
EOF
}
