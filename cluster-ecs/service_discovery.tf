# Dois namespaces do Cloud Map: um para service discovery por DNS e outro para o ECS Service Connect.
resource "aws_service_discovery_private_dns_namespace" "service_discovery" {
  name        = format("discovery.%s.internal", var.project_name)
  description = format("Service discovery (DNS) de %s", var.project_name)
  vpc         = var.vpc_id
}

resource "aws_service_discovery_private_dns_namespace" "service_connect" {
  name        = format("connect.%s.internal", var.project_name)
  description = format("ECS Service Connect de %s", var.project_name)
  vpc         = var.vpc_id
}
