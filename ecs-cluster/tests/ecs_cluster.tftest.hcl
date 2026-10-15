mock_provider "aws" {}

variables {
  name      = "test-ecs"
  vpc_id    = "vpc-12345678"
  namespace = "test.internal"
}

run "cluster_joins_the_namespace" {
  command = plan

  assert {
    condition     = aws_ecs_cluster.main.name == "test-ecs" && aws_service_discovery_private_dns_namespace.main.name == "test.internal"
    error_message = "Cluster and namespace names must come from the inputs."
  }
}

run "public_looking_namespace_is_rejected" {
  command = plan

  variables {
    namespace = "jonoma.com.br"
  }

  expect_failures = [var.namespace]
}
