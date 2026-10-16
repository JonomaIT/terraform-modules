mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_data "aws_vpc" {
    defaults = { id = "vpc-12345678", cidr_block = "10.10.0.0/16" }
  }
  mock_data "aws_subnets" {
    defaults = { ids = ["subnet-1", "subnet-2"] }
  }
  mock_data "aws_lb" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:111111111111:loadbalancer/app/x/1", security_groups = ["sg-alb"] }
  }
  mock_data "aws_ecs_cluster" {
    defaults = {
      arn                      = "arn:aws:ecs:us-east-1:111111111111:cluster/jonomait-stg-ecs"
      cluster_name             = "jonomait-stg-ecs"
      service_connect_defaults = [{ namespace = "arn:aws:servicediscovery:us-east-1:111111111111:namespace/ns-1" }]
    }
  }
  mock_data "aws_lb_listener" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:111111111111:listener/app/x/1/2" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_lb_target_group" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:111111111111:targetgroup/x/1" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/test" }
  }
  mock_resource "aws_ecs_task_definition" {
    defaults = { arn = "arn:aws:ecs:us-east-1:111111111111:task-definition/test:1" }
  }
}

variables {
  name        = "svc-hello"
  environment = "staging"
  image       = "111111111111.dkr.ecr.us-east-1.amazonaws.com/svc-hello:abc1234"
  port        = 8080
  hosts       = ["hello-stg.joshuel.com.br"]
}

run "public_app_gets_a_host_rule" {
  command = plan

  assert {
    condition     = length(aws_lb_listener_rule.app) == 1 && length(aws_lb_target_group.app) == 1
    error_message = "A public app needs a target group and a host rule on the shared ALB."
  }

  assert {
    condition     = aws_lb_listener_rule.app[0].priority >= 100 && aws_lb_listener_rule.app[0].priority <= 50000
    error_message = "App rule priorities are 100..50000 (1-99 belong to the platform)."
  }

  assert {
    condition     = aws_iam_role.task.name == "jonomait-stg-use1-svc-hello-task" && aws_ecs_task_definition.app.family == "jonomait-stg-svc-hello"
    error_message = "Names must follow the convention (IAM names carry the region)."
  }
}

run "internal_app_has_no_alb_pieces" {
  command = plan

  variables {
    hosts = []
  }

  assert {
    condition     = length(aws_lb_listener_rule.app) == 0 && length(aws_lb_target_group.app) == 0 && length(aws_vpc_security_group_ingress_rule.from_alb) == 0
    error_message = "An internal app must not touch the shared ALB."
  }
}

run "long_names_fit_the_target_group_limit" {
  command = plan

  variables {
    name = "svc-a-very-long-application-name"
  }

  assert {
    condition     = length(aws_lb_target_group.app[0].name) <= 32
    error_message = "Target group names are limited to 32 characters."
  }
}

run "latest_tag_is_rejected" {
  command = plan

  variables {
    image = "nginx:latest"
  }

  expect_failures = [var.image]
}
