remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = local.tfstate_path
  }
}

locals {
  fallback_user = get_env("USER")
  user = get_env("STATE_USER", local.fallback_user)
  tfstate_path = get_parent_terragrunt_dir() != "prod" ? "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${local.user}/terraform.tfstate" : "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"   
}

