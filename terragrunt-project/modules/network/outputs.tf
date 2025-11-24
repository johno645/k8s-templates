output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "network_name" {
  description = "Name of the network"
  value       = var.network_name
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = aws_subnet.public[*].id
}

output "subnet_count" {
  description = "Number of subnets created"
  value       = length(aws_subnet.public)
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
