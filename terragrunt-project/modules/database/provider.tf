# Kubernetes provider configuration for database module
# This overrides the default AWS provider from root

terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  # Configuration will come from kubeconfig or environment variables
  # Alternatively, you can specify:
  # config_path    = "~/.kube/config"
  # config_context = "my-context"
}
