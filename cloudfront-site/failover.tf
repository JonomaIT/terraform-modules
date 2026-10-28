# Origin failover (failover_region): a copy of the bucket in another region and a CloudFront
# origin group that reads it when the primary bucket answers 5xx or does not answer. The edge cache
# already covers most requests; this covers the files not cached while the primary region's S3 is
# down.
#
# The deploy uploads every build to both buckets (failover_bucket output). Not S3 replication: it
# only copies objects written after it is turned on, so files already in the bucket and left
# unchanged by later deploys would never reach the copy.

locals {
  failover        = var.failover_region != null
  failover_bucket = "${local.full_name}-${data.aws_caller_identity.current.account_id}-${coalesce(var.failover_region, "none")}"
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "failover" {
  count = local.failover ? 1 : 0

  region        = var.failover_region
  bucket        = local.failover_bucket
  force_destroy = var.force_destroy

  lifecycle {
    precondition {
      condition     = var.failover_region != data.aws_region.current.region
      error_message = "failover_region must be another region than the primary bucket's (${data.aws_region.current.region})."
    }

    precondition {
      condition     = length(local.failover_bucket) <= 63
      error_message = "The failover bucket name (${local.failover_bucket}) is longer than 63 characters: shorten the app name."
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "failover" {
  count = local.failover ? 1 : 0

  region = var.failover_region
  bucket = aws_s3_bucket.failover[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "failover" {
  count = local.failover ? 1 : 0

  region = var.failover_region
  bucket = aws_s3_bucket.failover[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "failover" {
  count = local.failover ? 1 : 0

  region = var.failover_region
  bucket = aws_s3_bucket.failover[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "failover" {
  count = local.failover ? 1 : 0

  region = var.failover_region
  bucket = aws_s3_bucket.failover[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "failover" {
  count = local.failover ? 1 : 0

  region = var.failover_region
  bucket = aws_s3_bucket.failover[0].id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.failover]
}

data "aws_iam_policy_document" "failover" {
  count = local.failover ? 1 : 0

  statement {
    sid       = "CloudFrontReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.failover[0].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "failover" {
  count = local.failover ? 1 : 0

  region = var.failover_region
  bucket = aws_s3_bucket.failover[0].id
  policy = data.aws_iam_policy_document.failover[0].json

  depends_on = [aws_s3_bucket_public_access_block.failover]
}
