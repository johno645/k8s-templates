output "application_name" {
  description = "Name of the application"
  value       = var.application_name
}

output "application_version" {
  description = "Version of the application"
  value       = var.application_version
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.application[0].dns_name : null
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.application[0].arn : null
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.application.name
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "desired_capacity" {
  description = "Desired capacity of the ASG"
  value       = aws_autoscaling_group.application.desired_capacity
}
