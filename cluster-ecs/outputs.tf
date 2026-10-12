output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "lb_external_arn" {
  description = "External load balancer ARN"
  value       = aws_lb.main.arn
}

output "lb_external_dns" {
  description = "External load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "lb_external_listener_arn" {
  description = "External load balancer HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "lb_internal_arn" {
  description = "Internal load balancer ARN"
  value       = aws_lb.internal.arn
}

output "lb_internal_dns" {
  description = "Internal load balancer DNS name"
  value       = aws_lb.internal.dns_name
}

output "lb_internal_listener_arn" {
  description = "Internal load balancer HTTP listener ARN"
  value       = aws_lb_listener.http_internal.arn
}

output "internal_zone_name" {
  description = "Private Route 53 zone pointing to the internal load balancer"
  value       = aws_route53_zone.private.name
}

output "service_discovery_namespace_id" {
  description = "Cloud Map service discovery namespace ID"
  value       = aws_service_discovery_private_dns_namespace.service_discovery.id
}

output "service_discovery_namespace_name" {
  description = "Cloud Map service discovery namespace name"
  value       = aws_service_discovery_private_dns_namespace.service_discovery.name
}

output "service_connect_namespace_id" {
  description = "Cloud Map Service Connect namespace ID"
  value       = aws_service_discovery_private_dns_namespace.service_connect.id
}

output "service_connect_namespace_name" {
  description = "Cloud Map Service Connect namespace name"
  value       = aws_service_discovery_private_dns_namespace.service_connect.name
}

output "vpc_link_id" {
  description = "API Gateway VPC Link ID"
  value       = aws_api_gateway_vpc_link.main.id
}

output "vpc_link_nlb_arn" {
  description = "ARN of the NLB targeted by the VPC Link"
  value       = aws_lb.vpc_link.arn
}
