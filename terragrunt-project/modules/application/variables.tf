variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "application_version" {
  description = "Version of the application to deploy"
  type        = string
  default     = "1.0.0"
}

variable "vpc_id" {
  description = "VPC ID where application will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for application deployment"
  type        = list(string)
}

variable "replica_count" {
  description = "Desired number of application instances"
  type        = number
  default     = 3
}

variable "min_instances" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 10
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "" # Will need to be provided or use data source
}

variable "enable_load_balancer" {
  description = "Whether to create a load balancer"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/"
}

variable "database_endpoint" {
  description = "Database endpoint for application configuration"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
