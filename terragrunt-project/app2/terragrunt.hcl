# Include the root terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

# Set the source of the module
terraform {
  source = "../modules/app2"
}

# State file configuration:
# The state file path is determined by the root terragrunt.hcl and includes:
# - Environment (dev/prod) from TG_ENVIRONMENT env var
# - App name (app2) from path_relative_to_include()
# 
# Example state file paths in GitLab:
# - dev environment: terraform/state/dev/app2/terraform.tfstate
# - prod environment: terraform/state/prod/app2/terraform.tfstate
#
# Note: app2 depends on app1 and will automatically apply app1 first if needed

# Make app2 dependent on app1
dependency "app1" {
  config_path = "../app1"
  
  mock_outputs = {
    bucket_name      = "app1-bucket"
    bucket_arn       = "arn:aws:s3:::app1-bucket"
    bucket_region    = "us-east-1"
    environment      = "dev"
  }
}

# Run pre-deployment script before applying
before_hook "pre_deploy" {
  commands     = ["apply"]
  execute      = ["bash", "${get_terragrunt_dir()}/pre-deploy.sh"]
  run_on_error = false
}

# Base variables from terraform.tfvars, plus dependency outputs
inputs = {
  app1_bucket         = dependency.app1.outputs.bucket_name
  app1_bucket_arn     = dependency.app1.outputs.bucket_arn
  app1_bucket_region  = dependency.app1.outputs.bucket_region
  app1_environment    = dependency.app1.outputs.environment
}
