output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs das subnets públicas, na mesma ordem de var.public_subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "IDs das subnets privadas, na mesma ordem de var.private_subnets"
  value       = aws_subnet.private[*].id
}
