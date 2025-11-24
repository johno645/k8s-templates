include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../Terraform/B"
}

dependency "app" {
  config_path = "../app"

  mock_outputs = {
    output = "mock"
  }
}

inputs = {
    name = dependency.app.outputs.output  
}
