# Network Component Terragrunt Configuration
# This creates STATE FILE #1 in GitLab

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
  source = "../../modules/network"
}

# Input values for the network module
inputs = {
  network_name = "${include.env.locals.environment}-vpc"
  vpc_cidr     = include.env.locals.vpc_cidr
  subnet_count = include.env.locals.subnet_count
  
  tags = merge(
    include.env.locals.common_tags,
    {
      Component = "network"
      Layer     = "infrastructure"
    }
  )
}
