# vpc

**Kind:** primitive. VPC, public and private subnets (tagged `Tier = public | private`), Internet Gateway, NAT Gateway per AZ or a single one (`single_nat_gateway`), free gateway endpoints for S3 and DynamoDB (that traffic skips the NAT).

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the vpc module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=vpc/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  project_name       = "acme-stg-network"
  cidr               = "10.10.0.0/16"
  single_nat_gateway = true # one NAT for the whole VPC: cheaper, fine outside production

  public_subnets = [
    { name = "public-a", cidr = "10.10.0.0/24", availability_zone = "us-east-1a" },
    { name = "public-b", cidr = "10.10.1.0/24", availability_zone = "us-east-1b" },
  ]
  private_subnets = [
    { name = "private-a", cidr = "10.10.10.0/24", availability_zone = "us-east-1a" },
    { name = "private-b", cidr = "10.10.11.0/24", availability_zone = "us-east-1b" },
  ]
}

output "vpc_id" {
  value = module.vpc.vpc_id
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
| cidr | VPC CIDR block (e.g. 10.10.0.0/16) | `string` | n/a | yes |
| gateway_endpoints | Gateway endpoints on the private route tables (free): s3, dynamodb | `list(string)` | ```[ "s3", "dynamodb" ]``` | no |
| private_subnets | Private subnets. Every AZ used here needs a public subnet, which hosts that AZ's NAT Gateway | ```list(object({ name = string cidr = string availability_zone = string }))``` | n/a | yes |
| project_name | Name of the VPC, used as a prefix for every resource created by this module (e.g. jonomait-stg-network) | `string` | n/a | yes |
| public_subnets | Public subnets. Each one gets a NAT Gateway (or only the first one, with single_nat_gateway) | ```list(object({ name = string cidr = string availability_zone = string }))``` | n/a | yes |
| single_nat_gateway | One NAT Gateway for the whole VPC instead of one per AZ. Cheaper (each NAT bills hourly), but private subnets lose internet egress if that AZ fails: fine for labs and non-production | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| gateway_endpoints | Gateway endpoint ID per service (s3, dynamodb) |
| nat_gateway_count | Number of NAT Gateways (1 with single_nat_gateway, otherwise one per public subnet) |
| vpc_cidr | VPC CIDR block |
| vpc_id | VPC ID |
<!-- END_TF_DOCS -->
