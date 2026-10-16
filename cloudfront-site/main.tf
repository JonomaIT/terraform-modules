# Pattern consumed by static sites (runtime = "cloudfront"): a private S3 bucket served by
# CloudFront through Origin Access Control. The site's public names come from the app-dns pattern
# (ADR-010), pointing at this distribution; Cloudflare stays in front (WAF, DDoS, Access).
# Must run with a provider in us-east-1: CloudFront only uses ACM certificates from there.

locals {
  env_short = { staging = "stg", production = "prd", "shared-services" = "shr" }[var.environment]
  full_name = "jonomait-${local.env_short}-${var.name}"
}

data "aws_caller_identity" "current" {}

# The platform's wildcard certificate (*.<zone>), issued by alb-shared in us-east-1: CloudFront
# reuses it instead of validating a certificate of its own.
data "aws_acm_certificate" "wildcard" {
  domain      = "*.${var.zone}"
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

# ------------------------------------------------------------------- bucket
# Account ID in the name: bucket names are global. Versioned, so a bad deploy can be rolled back;
# old versions expire after 30 days.
resource "aws_s3_bucket" "site" {
  bucket        = "${local.full_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3: the files are public through the site anyway; a customer managed key adds cost, not
# protection.
#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Only this distribution reads the bucket (OAC + SourceArn); nothing else, not even public URLs.
data "aws_iam_policy_document" "site" {
  statement {
    sid       = "CloudFrontReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

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

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# ------------------------------------------------------------- distribution
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = local.full_name
  description                       = "S3 origin of ${var.name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# No AWS WAF: Cloudflare (proxied) is the edge of every public name, with its WAF and DDoS
# protection. No access logs yet: they arrive with the log-archive pipeline.
#trivy:ignore:AVD-AWS-0011
#trivy:ignore:AVD-AWS-0010
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  default_root_object = "index.html"
  comment             = "${var.name} (${var.environment})"
  aliases             = var.hosts
  price_class         = var.price_class

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # A static site only reads: no POST/PUT/DELETE reaches the bucket.
  default_cache_behavior {
    target_origin_id           = "s3"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
  }

  # Single-page apps: unknown paths (403 from S3 with OAC) return index.html and the app routes.
  dynamic "custom_error_response" {
    for_each = var.spa ? [403, 404] : []

    content {
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 0
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.wildcard.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
