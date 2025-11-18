variable "environment" {
  description = "The environment (dev/staging/prod)"
  type        = string
}

variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "app1_bucket" {
  description = "The S3 bucket name from app1 (dependency)"
  type        = string
}

variable "app1_bucket_arn" {
  description = "The S3 bucket ARN from app1"
  type        = string
}

variable "app1_bucket_region" {
  description = "The region of app1's S3 bucket"
  type        = string
}

variable "app1_environment" {
  description = "The environment that app1 is deployed in"
  type        = string
}

# Example resource - replace with your actual resources
# This table depends on app1's S3 bucket (var.app1_bucket)
resource "aws_dynamodb_table" "app2_table" {
  name           = "${var.app_name}-${var.environment}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment      = var.environment
    ManagedBy        = "terraform"
    DependsOnBucket  = var.app1_bucket
    DependsOnRegion  = var.app1_bucket_region
  }
}

# Outputs
output "table_name" {
  value       = aws_dynamodb_table.app2_table.name
  description = "The name of the DynamoDB table created by app2"
}

output "table_arn" {
  value       = aws_dynamodb_table.app2_table.arn
  description = "The ARN of the DynamoDB table"
}

# Pass through app1 outputs
output "app1_bucket_name" {
  value       = var.app1_bucket
  description = "The S3 bucket name from app1 (passed through)"
}

output "app1_bucket_arn" {
  value       = var.app1_bucket_arn
  description = "The S3 bucket ARN from app1 (passed through)"
}

output "app1_bucket_region" {
  value       = var.app1_bucket_region
  description = "The region of app1's S3 bucket (passed through)"
}

output "app1_environment" {
  value       = var.app1_environment
  description = "The environment that app1 is deployed in (passed through)"
}
