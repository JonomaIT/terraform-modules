# dynamodb-table

**Kind:** data. Table in every region of the app (global table: replicas in sync, last writer wins), on demand, point-in-time recovery, deletion protection (off only in labs), optional sort key and TTL.

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the dynamodb-table module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//dynamodb-table?ref=dynamodb-table/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "orders" {
  source = "../../"

  name     = "acme-stg-svc-orders-orders"
  regions  = ["us-east-1", "sa-east-1"] # first region holds the global table, the rest are replicas
  hash_key = "order_id"

  deletion_protection = false # labs only
}
```

More in [`examples/`](examples/). Every release of this module is a tag `<module>/vX.Y.Z`, listed in [`CHANGELOG.md`](CHANGELOG.md).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| aws | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deletion_protection | Refuse to delete the table (and its replicas). Only labs turn it off, to be destroyed at the end of the day | `bool` | `true` | no |
| hash_key | Partition key attribute | `string` | n/a | yes |
| hash_key_type | Type of the partition key: S (string), N (number) or B (binary) | `string` | `"S"` | no |
| name | Table name, the same in every region (e.g. jonomait-prd-svc-vendas-pedidos) | `string` | n/a | yes |
| point_in_time_recovery | Continuous backups: restore the table to any second of the last 35 days | `bool` | `true` | no |
| range_key | Sort key attribute (null = partition key only) | `string` | `null` | no |
| range_key_type | Type of the sort key: S, N or B | `string` | `"S"` | no |
| regions | Regions of the app, primary first: the table lives in the first one and every other one gets a replica | `list(string)` | n/a | yes |
| ttl_attribute | Attribute holding an expiry time (Unix seconds): DynamoDB deletes expired items for free (null = no TTL) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arns | Table ARN in each region (region => ARN) |
| name | Table name (the same in every region) |
<!-- END_TF_DOCS -->
