mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
}

variables {
  project_name = "test-network"
  cidr         = "10.10.0.0/16"
  public_subnets = [
    { name = "public-a", cidr = "10.10.48.0/24", availability_zone = "us-east-1a" },
    { name = "public-b", cidr = "10.10.49.0/24", availability_zone = "us-east-1b" },
  ]
  private_subnets = [
    { name = "private-a", cidr = "10.10.0.0/20", availability_zone = "us-east-1a" },
    { name = "private-b", cidr = "10.10.16.0/20", availability_zone = "us-east-1b" },
  ]
}

run "one_nat_per_az_by_default" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.private) == 2
    error_message = "Expected one NAT Gateway per public subnet."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.private : s.tags.Tier == "private"]) && alltrue([for s in aws_subnet.public : s.tags.Tier == "public"])
    error_message = "Subnets must carry the Tier tag other components look them up by."
  }
}

run "single_nat_gateway" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.private) == 1 && length(aws_eip.eip) == 1
    error_message = "single_nat_gateway must create exactly one NAT Gateway and one EIP."
  }
}

run "s3_and_dynamodb_skip_the_nat" {
  command = plan

  assert {
    condition = (
      aws_vpc_endpoint.gateway["dynamodb"].service_name == "com.amazonaws.us-east-1.dynamodb" &&
      aws_vpc_endpoint.gateway["s3"].vpc_endpoint_type == "Gateway"
    )
    error_message = "Gateway endpoints for S3 and DynamoDB by default (free, no NAT charge)."
  }
}

run "unknown_gateway_endpoint_is_rejected" {
  command = plan

  variables {
    gateway_endpoints = ["sqs"]
  }

  expect_failures = [var.gateway_endpoints]
}

run "private_subnet_without_public_in_its_az_is_rejected" {
  command = plan

  variables {
    private_subnets = [{ name = "private-c", cidr = "10.10.32.0/20", availability_zone = "us-east-1c" }]
  }

  expect_failures = [var.private_subnets]
}
