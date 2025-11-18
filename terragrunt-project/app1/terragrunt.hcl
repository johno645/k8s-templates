# Include the root terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

# Set the source of the module
terraform {
  source = "../modules/app1"
}

# State file configuration:
# The state file path is determined by the root terragrunt.hcl and includes:
# - Environment (dev/prod) from TG_ENVIRONMENT env var
# - App name (app1) from path_relative_to_include()
# 
# Example state file paths in GitLab:
# - dev environment: terraform/state/dev/app1/terraform.tfstate
# - prod environment: terraform/state/prod/app1/terraform.tfstate
#
# Usage:
# Deploy to dev:
#   export TG_ENVIRONMENT=dev
#   export TG_GITLAB_PROJECT_ID=12345
#   terragrunt apply -var-file=../terraform.dev.tfvars
#
# Deploy to prod:
#   export TG_ENVIRONMENT=prod
#   export TG_GITLAB_PROJECT_ID=67890
#   terragrunt apply -var-file=../terraform.prod.tfvars
