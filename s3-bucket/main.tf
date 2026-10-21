# A private bucket in every region of the app, named <name>-<region> (bucket names are global).
# With replicate, every object written in one region is copied to the other regions' buckets, in
# both directions: each region reads and writes its own bucket and still sees everything.
#
# Never public, TLS only, versioned (needed by replication, and a deleted or overwritten object can
# be recovered); old versions expire after noncurrent_days.

locals {
  buckets   = { for r in var.regions : r => "${var.name}-${r}" }
  replicate = var.replicate && length(var.regions) > 1
}

resource "aws_s3_bucket" "main" {
  for_each = local.buckets

  region        = each.key
  bucket        = each.value
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "main" {
  for_each = aws_s3_bucket.main

  region = each.key
  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  for_each = aws_s3_bucket.main

  region                  = each.key
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "main" {
  for_each = aws_s3_bucket.main

  region = each.key
  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3: replication works without key grants; a customer managed key would bill per region and
# need a key policy for the replication role in each one.
#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = aws_s3_bucket.main

  region = each.key
  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = aws_s3_bucket.main

  region = each.key
  bucket = each.value.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Lifecycle and replication both need versioning on.
  depends_on = [aws_s3_bucket_versioning.main]
}

data "aws_iam_policy_document" "bucket" {
  for_each = aws_s3_bucket.main

  statement {
    sid     = "DenyWithoutTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      each.value.arn,
      "${each.value.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  for_each = aws_s3_bucket.main

  region = each.key
  bucket = each.value.id
  policy = data.aws_iam_policy_document.bucket[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# ---------------------------------------------------------------- replication
data "aws_iam_policy_document" "replication_trust" {
  count = local.replicate ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  count = local.replicate ? 1 : 0

  name               = "${var.name}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_trust[0].json
}

data "aws_iam_policy_document" "replication" {
  count = local.replicate ? 1 : 0

  statement {
    sid       = "ReadReplicationConfiguration"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [for b in aws_s3_bucket.main : b.arn]
  }

  statement {
    sid = "ReadSourceVersions"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = [for b in aws_s3_bucket.main : "${b.arn}/*"]
  }

  statement {
    sid       = "WriteReplicas"
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resources = [for b in aws_s3_bucket.main : "${b.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  count = local.replicate ? 1 : 0

  name   = "replicate-between-regions"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication[0].json
}

# Each bucket copies to every other region's bucket. Objects that arrived as replicas are not
# copied again, so two-way replication does not loop.
resource "aws_s3_bucket_replication_configuration" "main" {
  for_each = local.replicate ? aws_s3_bucket.main : {}

  region = each.key
  bucket = each.value.id
  role   = aws_iam_role.replication[0].arn

  dynamic "rule" {
    for_each = [for r in var.regions : r if r != each.key]

    content {
      id       = "to-${rule.value}"
      priority = index(var.regions, rule.value)
      status   = "Enabled"

      filter {}

      delete_marker_replication {
        status = "Enabled"
      }

      destination {
        bucket        = aws_s3_bucket.main[rule.value].arn
        storage_class = "STANDARD"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main, aws_iam_role_policy.replication]
}
