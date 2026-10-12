# Two Cloud Map namespaces: one for DNS-based service discovery and one for ECS Service Connect.
resource "aws_service_discovery_private_dns_namespace" "service_discovery" {
  name        = format("discovery.%s.internal", var.project_name)
  description = format("Service discovery (DNS) for %s", var.project_name)
  vpc         = var.vpc_id
}

resource "aws_service_discovery_private_dns_namespace" "service_connect" {
  name        = format("connect.%s.internal", var.project_name)
  description = format("ECS Service Connect for %s", var.project_name)
  vpc         = var.vpc_id
}
