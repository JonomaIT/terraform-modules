# A DynamoDB table in every region of the app: a global table (version 2019.11.21) held in the
# first region, with a replica in each other one, kept in sync by AWS (last writer wins, usually
# under a second). Apps read and write in their own region.
#
# On demand: no capacity to plan or autoscale, nothing billed while idle. Point-in-time recovery
# on, and protected against deletion unless deletion_protection is false (labs only).

locals {
  replicas = slice(var.regions, 1, length(var.regions))

  attributes = merge(
    { (var.hash_key) = var.hash_key_type },
    var.range_key == null ? {} : { (var.range_key) = var.range_key_type },
  )
}

# Encrypted at rest with the AWS owned key: a customer managed key bills per key and per region
# and adds nothing for app data that never leaves the account.
#trivy:ignore:AVD-AWS-0025
resource "aws_dynamodb_table" "main" {
  region       = var.regions[0]
  name         = var.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key
  range_key    = var.range_key

  dynamic "attribute" {
    for_each = local.attributes

    content {
      name = attribute.key
      type = attribute.value
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute == null ? [] : [var.ttl_attribute]

    content {
      attribute_name = ttl.value
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  # Replicas read the changes from the stream: required by global tables.
  stream_enabled   = length(local.replicas) > 0
  stream_view_type = length(local.replicas) > 0 ? "NEW_AND_OLD_IMAGES" : null

  dynamic "replica" {
    for_each = local.replicas

    content {
      region_name                 = replica.value
      point_in_time_recovery      = var.point_in_time_recovery
      deletion_protection_enabled = var.deletion_protection
      propagate_tags              = true
    }
  }
}
