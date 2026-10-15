mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.10.0.0/16" }
  }
}

variables {
  name            = "test-alb-shared"
  vpc_id          = "vpc-12345678"
  subnets         = ["subnet-1", "subnet-2"]
  certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/test"
  ingress_cidrs   = ["173.245.48.0/20", "103.21.244.0/22"]
}

run "https_only_from_the_allowed_sources" {
  command = plan

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.https) == 2 && alltrue([for r in aws_vpc_security_group_ingress_rule.https : r.from_port == 443 && r.to_port == 443])
    error_message = "One port-443 rule per allowed source, and nothing else."
  }

  assert {
    condition     = aws_lb_listener.https.port == 443 && aws_lb_listener.https.protocol == "HTTPS"
    error_message = "The only listener is HTTPS on 443."
  }

  assert {
    condition     = aws_lb.main.internal == false && aws_lb.main.drop_invalid_header_fields == true
    error_message = "Internet-facing ALB that drops invalid headers."
  }
}

run "single_subnet_is_rejected" {
  command = plan

  variables {
    subnets = ["subnet-1"]
  }

  expect_failures = [var.subnets]
}
