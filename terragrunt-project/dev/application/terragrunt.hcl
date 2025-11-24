# Application Component Terragrunt Configuration
# This creates STATE FILE #3 in GitLab

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
  source = "../../modules/application"
}

# Define dependencies - application depends on both network and database
dependency "network" {
  config_path = "../network"
  
  mock_outputs = {
    vpc_id       = "mock-vpc-id"
    network_name = "mock-network"
    subnet_ids   = ["mock-subnet-1", "mock-subnet-2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "database" {
  config_path = "../database"
  
  mock_outputs = {
    database_name    = "mock-database"
    service_endpoint = "mock-db.database.svc.cluster.local"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# Get latest Amazon Linux 2 AMI
locals {
  # You can also use a data source in the module or specify a specific AMI ID
  ami_id = get_env("AMI_ID", "") # Set AMI_ID env var or update this
}

# Input values for the application module
inputs = {
  application_name    = include.env.locals.application_name
  application_version = include.env.locals.application_version
  
  # Network configuration from network module
  vpc_id     = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.subnet_ids
  
  # Auto Scaling configuration
  replica_count = include.env.locals.desired_capacity
  min_instances = include.env.locals.min_instances
  max_instances = include.env.locals.max_instances
  
  # Instance configuration
  instance_type = include.env.locals.instance_type
  ami_id        = local.ami_id # Needs to be set via env var or hardcoded
  
  # Load balancer configuration
  enable_load_balancer = include.env.locals.enable_load_balancer
  health_check_path    = include.env.locals.health_check_path
  
  # Database connection
  database_endpoint = dependency.database.outputs.service_endpoint
  
  tags = merge(
    include.env.locals.common_tags,
    {
      Component = "application"
      Layer     = "compute"
      Network   = dependency.network.outputs.network_name
      Database  = dependency.database.outputs.database_name
    }
  )
}
