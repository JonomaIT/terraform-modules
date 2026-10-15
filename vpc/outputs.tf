output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways (1 with single_nat_gateway, otherwise one per public subnet)"
  value       = length(aws_nat_gateway.private)
}
