# sqs-queue

**Kind:** data. Queue + dead-letter queue in every region of the app, encrypted, long polling, TLS only. Subscribes every region's queue to the listed topics of any region (cross-region fan-out).

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the sqs-queue module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//sqs-queue?ref=sqs-queue/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "billing" {
  source = "../../"

  name    = "acme-stg-svc-billing-orders"
  regions = ["us-east-1", "sa-east-1"]

  # every region's queue gets the messages published in every region
  subscribe_topic_arns = [
    "arn:aws:sns:us-east-1:111111111111:acme-stg-svc-orders-order-created",
    "arn:aws:sns:sa-east-1:111111111111:acme-stg-svc-orders-order-created",
  ]
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
| max_receive_count | Failed receives before a message moves to the dead-letter queue | `number` | `5` | no |
| name | Queue name, the same in every region (the dead-letter queue is <name>-dlq) | `string` | n/a | yes |
| regions | Regions of the app: one queue (and dead-letter queue) in each | `list(string)` | n/a | yes |
| retention_days | Days an unprocessed message is kept. Covers how long a region can stay passive or down and still process its backlog | `number` | `4` | no |
| standby | Several regions only: each region's queue gets only its own region's topics, and a <name>-standby queue gets the other regions' copies, to consume while another region is out (ADR-013, active/active). false: every queue gets every region's topics (ADR-012) | `bool` | `false` | no |
| subscribe_topic_arns | SNS topics (any region of the account) whose messages every queue receives | `list(string)` | `[]` | no |
| visibility_timeout | Seconds a received message stays hidden from other consumers; longer than the processing of one message | `number` | `60` | no |

## Outputs

| Name | Description |
|------|-------------|
| arns | Queue ARN in each region (region => ARN) |
| dlq_arns | Dead-letter queue ARN in each region (region => ARN) |
| name | Queue name (the same in every region) |
| standby_arns | Standby queue ARN in each region (region => ARN); empty without standby |
| standby_urls | Standby queue URL in each region (region => URL); empty without standby |
| urls | Queue URL in each region (region => URL), what the SDKs use |
<!-- END_TF_DOCS -->
