# sns-topic

**Kind:** data. Topic in every region of the app, encrypted, usable only by the account and only over TLS.

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the sns-topic module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//sns-topic?ref=sns-topic/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "order_created" {
  source = "../../"

  name    = "acme-stg-svc-orders-order-created"
  regions = ["us-east-1", "sa-east-1"]
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
| name | Topic name, the same in every region (e.g. jonomait-prd-svc-vendas-pedido-criado) | `string` | n/a | yes |
| regions | Regions of the app: one topic in each | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| arns | Topic ARN in each region (region => ARN) |
| name | Topic name (the same in every region) |
<!-- END_TF_DOCS -->
