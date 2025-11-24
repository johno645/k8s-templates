variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for database resources"
  type        = string
  default     = "database"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "replicas" {
  description = "Number of database replicas"
  type        = number
  default     = 1
}

variable "storage_size" {
  description = "Size of persistent storage"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for persistent volume"
  type        = string
  default     = "standard"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "cpu_request" {
  description = "CPU request for database container"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit for database container"
  type        = string
  default     = "1000m"
}

variable "memory_request" {
  description = "Memory request for database container"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit for database container"
  type        = string
  default     = "1Gi"
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
}

variable "tags" {
  description = "Labels to apply to Kubernetes resources"
  type        = map(string)
  default     = {}
}
