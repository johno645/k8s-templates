output "database_name" {
  description = "Name of the database"
  value       = var.database_name
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.database.metadata[0].name
}

output "service_name" {
  description = "Kubernetes service name"
  value       = kubernetes_service.database.metadata[0].name
}

output "service_endpoint" {
  description = "Database service endpoint"
  value       = "${kubernetes_service.database.metadata[0].name}.${kubernetes_namespace.database.metadata[0].name}.svc.cluster.local"
}

output "service_port" {
  description = "Database service port"
  value       = 5432
}

output "deployment_name" {
  description = "Kubernetes deployment name"
  value       = kubernetes_deployment.database.metadata[0].name
}
