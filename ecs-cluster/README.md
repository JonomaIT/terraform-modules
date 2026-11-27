# ecs-cluster

**Kind:** primitive. ECS cluster (Fargate and Fargate Spot) and the private namespace for service-to-service names (`<app>.<prefix>.internal`, ECS Service Connect).

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the ecs-cluster module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//ecs-cluster?ref=ecs-cluster/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "cluster" {
  source = "../../"

  name      = "acme-stg-ecs"
  namespace = "acme.internal" # services find each other at <app>.acme.internal
  vpc_id    = "vpc-0123456789abcdef0"
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
| container_insights | Container Insights: enabled, enhanced or disabled (enabled/enhanced incur CloudWatch costs) | `string` | `"enabled"` | no |
| name | Cluster name (e.g. jonomait-stg-ecs) | `string` | n/a | yes |
| namespace | Private DNS namespace for service-to-service traffic (e.g. jonomait.internal) | `string` | n/a | yes |
| vpc_id | VPC where the private namespace is created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | ECS cluster name |
| namespace_name | Private namespace name |
<!-- END_TF_DOCS -->
