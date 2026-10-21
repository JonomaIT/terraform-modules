mock_provider "aws" {
  mock_resource "aws_dynamodb_table" {
    defaults = { arn = "arn:aws:dynamodb:us-east-1:111111111111:table/jonomait-prd-svc-vendas-pedidos" }
  }
}

variables {
  name     = "jonomait-prd-svc-vendas-pedidos"
  regions  = ["us-east-1", "sa-east-1"]
  hash_key = "id"
}

run "global_table_on_demand_and_protected" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.main.region == "us-east-1" && length(aws_dynamodb_table.main.replica) == 1 && one(aws_dynamodb_table.main.replica).region_name == "sa-east-1"
    error_message = "The table lives in the first region, with a replica in each other one."
  }

  assert {
    condition     = aws_dynamodb_table.main.billing_mode == "PAY_PER_REQUEST" && aws_dynamodb_table.main.stream_view_type == "NEW_AND_OLD_IMAGES"
    error_message = "On demand, and the stream global tables need."
  }

  assert {
    condition     = aws_dynamodb_table.main.deletion_protection_enabled && aws_dynamodb_table.main.point_in_time_recovery[0].enabled
    error_message = "Protected against deletion, with point-in-time recovery, by default."
  }
}

run "arns_in_every_region" {
  command = apply

  assert {
    condition     = output.arns["sa-east-1"] == "arn:aws:dynamodb:sa-east-1:111111111111:table/jonomait-prd-svc-vendas-pedidos"
    error_message = "Every region's ARN is published, so apps get access to their own copy."
  }
}

run "single_region_has_no_replica_nor_stream" {
  command = plan

  variables {
    regions = ["us-east-1"]
  }

  assert {
    condition     = length(aws_dynamodb_table.main.replica) == 0 && !aws_dynamodb_table.main.stream_enabled
    error_message = "One region: a plain table."
  }
}

run "sort_key_and_ttl" {
  command = plan

  variables {
    range_key      = "created_at"
    range_key_type = "N"
    ttl_attribute  = "expires_at"
  }

  assert {
    condition     = length(aws_dynamodb_table.main.attribute) == 2 && aws_dynamodb_table.main.ttl[0].attribute_name == "expires_at"
    error_message = "Only key attributes are declared; the TTL attribute is not one of them."
  }
}

run "invalid_key_type_is_rejected" {
  command = plan

  variables {
    hash_key_type = "string"
  }

  expect_failures = [var.hash_key_type]
}
