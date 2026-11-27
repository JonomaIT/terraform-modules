# s3-bucket

**Kind:** data. Private bucket in every region of the app (`<name>-<region>`), versioned, TLS only, old versions expire; optional two-way replication between the regions.

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the s3-bucket module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//s3-bucket?ref=s3-bucket/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "uploads" {
  source = "../../"

  name    = "acme-stg-svc-orders-uploads" # becomes acme-stg-svc-orders-uploads-<region>
  regions = ["us-east-1", "sa-east-1"]    # with replicate (default), both buckets see every object
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
| force_destroy | Allow destroying the buckets with objects inside. Only labs turn it on | `bool` | `false` | no |
| name | Base name; each region's bucket is <name>-<region> (e.g. jonomait-prd-svc-vendas-arquivo-sa-east-1) | `string` | n/a | yes |
| noncurrent_days | Days an overwritten or deleted object version is kept before it expires | `number` | `30` | no |
| regions | Regions of the app: one bucket in each | `list(string)` | n/a | yes |
| replicate | Copy every object to the other regions' buckets, in both directions (no effect with one region) | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| arns | Bucket ARN in each region (region => ARN) |
| names | Bucket name in each region (region => name) |
<!-- END_TF_DOCS -->
