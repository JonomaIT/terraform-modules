output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "namespace_name" {
  description = "Private namespace name"
  value       = aws_service_discovery_private_dns_namespace.main.name
}
