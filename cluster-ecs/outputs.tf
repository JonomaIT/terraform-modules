output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "lb_external_arn" {
  description = "ARN do load balancer externo"
  value       = aws_lb.main.arn
}

output "lb_external_dns" {
  description = "DNS do load balancer externo"
  value       = aws_lb.main.dns_name
}

output "lb_external_listener_arn" {
  description = "ARN do listener HTTP do load balancer externo"
  value       = aws_lb_listener.http.arn
}

output "lb_internal_arn" {
  description = "ARN do load balancer interno"
  value       = aws_lb.internal.arn
}

output "lb_internal_dns" {
  description = "DNS do load balancer interno"
  value       = aws_lb.internal.dns_name
}

output "lb_internal_listener_arn" {
  description = "ARN do listener HTTP do load balancer interno"
  value       = aws_lb_listener.http_internal.arn
}

output "internal_zone_name" {
  description = "Zona privada do Route 53 que aponta para o load balancer interno"
  value       = aws_route53_zone.private.name
}

output "service_discovery_namespace_id" {
  description = "ID do namespace Cloud Map de service discovery"
  value       = aws_service_discovery_private_dns_namespace.service_discovery.id
}

output "service_discovery_namespace_name" {
  description = "Nome do namespace Cloud Map de service discovery"
  value       = aws_service_discovery_private_dns_namespace.service_discovery.name
}

output "service_connect_namespace_id" {
  description = "ID do namespace Cloud Map do Service Connect"
  value       = aws_service_discovery_private_dns_namespace.service_connect.id
}

output "service_connect_namespace_name" {
  description = "Nome do namespace Cloud Map do Service Connect"
  value       = aws_service_discovery_private_dns_namespace.service_connect.name
}

output "vpc_link_id" {
  description = "ID do VPC Link do API Gateway"
  value       = aws_api_gateway_vpc_link.main.id
}

output "vpc_link_nlb_arn" {
  description = "ARN do NLB alvo do VPC Link"
  value       = aws_lb.vpc_link.arn
}
