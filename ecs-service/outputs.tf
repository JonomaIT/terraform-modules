output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "internal_url" {
  description = "Service-to-service address (Service Connect)"
  value       = "http://${var.name}.${local.namespace}:${var.port}"
}

output "public_hosts" {
  description = "Public names routed to the app (empty for internal apps)"
  value       = var.hosts
}

output "log_group" {
  description = "CloudWatch Logs group of the app"
  value       = aws_cloudwatch_log_group.app.name
}
