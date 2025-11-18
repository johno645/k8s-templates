variable "environment" {
  description = "The environment (dev/staging/prod)"
  type        = string
}

variable "app_name" {
  description = "The name of the application"
  type        = string
}

# Example resource - replace with your actual resources
resource "aws_s3_bucket" "app1_bucket" {
  bucket = "${var.app_name}-${var.environment}-bucket"
  
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Outputs
output "bucket_name" {
  value       = aws_s3_bucket.app1_bucket.id
  description = "The name of the S3 bucket created by app1"
}

output "bucket_arn" {
  value       = aws_s3_bucket.app1_bucket.arn
  description = "The ARN of the S3 bucket created by app1"
}

output "bucket_region" {
  value       = aws_s3_bucket.app1_bucket.region
  description = "The region of the S3 bucket"
}

output "environment" {
  value       = var.environment
  description = "The environment this app1 is deployed in"
}
