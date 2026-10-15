# ECS cluster (Fargate) and the private namespace services use to find each other
# (<app>.<namespace>, e.g. svc-compras.jonomait.internal), through ECS Service Connect.
# The ".internal" TLD is reserved for private use (ICANN, 2024): it never collides with a public domain.

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = var.namespace
  description = format("Service-to-service names for %s", var.name)
  vpc         = var.vpc_id
}

resource "aws_ecs_cluster" "main" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  # Services join this namespace by default when they enable Service Connect.
  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.main.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  # Spot is available to services that ask for it (e.g. staging); the default is on-demand.
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }
}
