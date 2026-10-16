mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_acm_certificate" {
    defaults = { arn = "arn:aws:acm:us-east-1:111111111111:certificate/test" }
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
