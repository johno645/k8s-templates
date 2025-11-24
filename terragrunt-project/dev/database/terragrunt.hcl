# Database Component Terragrunt Configuration
# This creates STATE FILE #2 in GitLab
# Uses Kubernetes provider instead of AWS

# Include the root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include environment-specific configuration
include "env" {
  path = find_in_parent_folders("env.hcl")
}

# Specify the Terraform module to use
terraform {
  source = "../../modules/database"
}

# Override the default AWS provider with Kubernetes provider
generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
# This overrides the AWS provider from root config
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  # Uses default kubeconfig or environment variables
  # Set KUBECONFIG env var or use ~/.kube/config
}
EOF
}

# Define dependencies - database depends on network being created first
dependency "network" {
  config_path = "../network"
  
  # Mock outputs for plan/validate commands
  mock_outputs = {
    vpc_id       = "mock-vpc-id"
    network_name = "mock-network"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# Input values for the database module
inputs = {
  database_name     = include.env.locals.database_name
  namespace         = include.env.locals.namespace
  postgres_version  = include.env.locals.postgres_version
  replicas          = include.env.locals.db_replicas
  storage_size      = include.env.locals.storage_size
  storage_class     = include.env.locals.storage_class
  
  # Credentials - in production, use secrets management
  database_user     = get_env("DB_USER", "postgres")
  database_password = get_env("DB_PASSWORD", "changeme123")
  
  # Resource limits
  cpu_request    = include.env.locals.db_cpu_request
  cpu_limit      = include.env.locals.db_cpu_limit
  memory_request = include.env.locals.db_memory_request
  memory_limit   = include.env.locals.db_memory_limit
  
  service_type = "ClusterIP"
  
  tags = merge(
    include.env.locals.common_tags,
    {
      Component = "database"
      Layer     = "data"
      Network   = dependency.network.outputs.network_name
    }
  )
}
