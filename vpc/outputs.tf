output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "Public subnet IDs, in the same order as var.public_subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "Private subnet IDs, in the same order as var.private_subnets"
  value       = aws_subnet.private[*].id
}
