mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_acm_certificate" {
    defaults = { arn = "arn:aws:acm:us-east-1:111111111111:certificate/test" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_cloudfront_distribution" {
    defaults = { arn = "arn:aws:cloudfront::111111111111:distribution/TEST" }
  }
}

variables {
  name        = "web-app"
  environment = "production"
  zone        = "example.com"
  hosts       = ["app.example.com"]
}

run "private_bucket_read_only_through_cloudfront" {
  command = plan

  assert {
    condition     = aws_s3_bucket.site.bucket == "jonomait-prd-web-app-111111111111"
    error_message = "Bucket named jonomait-<env>-<app>-<account>."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.site.restrict_public_buckets && aws_s3_bucket_public_access_block.site.block_public_policy
    error_message = "The bucket is never public: only CloudFront (OAC) reads it."
  }

  assert {
    condition = (
      toset(aws_cloudfront_distribution.site.default_cache_behavior[0].allowed_methods) == toset(["GET", "HEAD", "OPTIONS"]) &&
      aws_cloudfront_distribution.site.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    )
    error_message = "A static site only reads, over HTTPS."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.site.custom_error_response) == 0
    error_message = "Without spa, missing pages are real errors."
  }
}

run "one_bucket_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket.failover) == 0 && length(aws_cloudfront_distribution.site.origin_group) == 0 && aws_cloudfront_distribution.site.default_cache_behavior[0].target_origin_id == "s3"
    error_message = "Without failover_region: one bucket, one origin."
  }
}

run "failover_bucket_in_another_region" {
  command = plan

  variables {
    failover_region = "sa-east-1"
  }

  assert {
    condition     = aws_s3_bucket.failover[0].bucket == "jonomait-prd-web-app-111111111111-sa-east-1" && aws_s3_bucket.failover[0].region == "sa-east-1"
    error_message = "The replica is jonomait-<env>-<app>-<account>-<region>, in that region."
  }

  assert {
    condition = (
      aws_cloudfront_distribution.site.default_cache_behavior[0].target_origin_id == "s3-group" &&
      toset([for m in one(aws_cloudfront_distribution.site.origin_group).member : m.origin_id]) == toset(["s3", "s3-failover"]) &&
      toset(one(one(aws_cloudfront_distribution.site.origin_group).failover_criteria).status_codes) == toset([500, 502, 503, 504])
    )
    error_message = "CloudFront reads the replica when the primary answers 5xx (not 403/404, the SPA's paths)."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.failover[0].restrict_public_buckets && aws_s3_bucket_versioning.failover[0].versioning_configuration[0].status == "Enabled"
    error_message = "The replica is as private (and versioned) as the primary."
  }
}

run "failover_in_the_same_region_is_refused" {
  command = plan

  variables {
    failover_region = "us-east-1"
  }

  expect_failures = [aws_s3_bucket.failover]
}

run "spa_returns_index_for_unknown_paths" {
  command = plan

  variables {
    spa = true
  }

  assert {
    condition     = length(aws_cloudfront_distribution.site.custom_error_response) == 2
    error_message = "A single-page app maps 403 and 404 to /index.html."
  }
}
