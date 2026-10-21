mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/test" }
  }
}

variables {
  name    = "jonomait-prd-svc-vendas-arquivo"
  regions = ["us-east-1", "sa-east-1"]
}

run "private_versioned_bucket_per_region" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main["sa-east-1"].bucket == "jonomait-prd-svc-vendas-arquivo-sa-east-1" && aws_s3_bucket.main["sa-east-1"].region == "sa-east-1"
    error_message = "One bucket per region, named <name>-<region>."
  }

  assert {
    condition     = alltrue([for p in aws_s3_bucket_public_access_block.main : p.block_public_policy && p.restrict_public_buckets])
    error_message = "Buckets are never public."
  }

  assert {
    condition     = alltrue([for v in aws_s3_bucket_versioning.main : v.versioning_configuration[0].status == "Enabled"]) && !aws_s3_bucket.main["us-east-1"].force_destroy
    error_message = "Versioned, and a bucket with objects is not destroyed by default."
  }
}

run "two_way_replication" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_replication_configuration.main) == 2 && length(aws_iam_role.replication) == 1
    error_message = "Each region's bucket replicates to the other, with one replication role."
  }

  assert {
    condition     = one(aws_s3_bucket_replication_configuration.main["us-east-1"].rule).id == "to-sa-east-1"
    error_message = "us-east-1 copies to sa-east-1 (and sa-east-1 to us-east-1)."
  }
}

run "single_region_does_not_replicate" {
  command = plan

  variables {
    regions = ["us-east-1"]
  }

  assert {
    condition     = length(aws_s3_bucket_replication_configuration.main) == 0 && length(aws_iam_role.replication) == 0
    error_message = "Nothing to replicate to with one region."
  }
}

run "long_names_are_rejected" {
  command = plan

  variables {
    name = "jonomait-prd-svc-a-very-long-application-name-arquivo"
  }

  expect_failures = [var.name]
}
