# alb

**Kind:** primitive. Shared internet-facing ALB: HTTPS only (no port 80, fail closed), only from `ingress_cidrs` (Cloudflare's ranges), default answer `404 <name> (<region>)`. `/health` on `ingress_host` answers `200 ok <region>`: the region check of the edge.

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the alb module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//alb?ref=alb/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

data "cloudflare_ip_ranges" "edge" {}

module "alb" {
  source = "../../"

  name            = "acme-stg-alb-shared"
  vpc_id          = "vpc-0123456789abcdef0"
  subnets         = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/example"
  ingress_host    = "ingress-use1.stg.example.com"
  ingress_cidrs   = data.cloudflare_ip_ranges.edge.ipv4_cidrs # only Cloudflare reaches the ALB
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
| certificate_arn | ACM certificate of the HTTPS listener (validated, in the ALB's region) | `string` | n/a | yes |
| deletion_protection | Refuse to delete the ALB (true in production) | `bool` | `false` | no |
| ingress_cidrs | Sources allowed on port 443, e.g. Cloudflare's IP ranges so traffic only comes through Cloudflare | `list(string)` | n/a | yes |
| ingress_host | Entry name of the environment (e.g. ingress.jonoma.com.br): its /health answers 200, the region check of the edge | `string` | n/a | yes |
| name | ALB name (e.g. jonomait-stg-alb-shared); also the security group prefix | `string` | n/a | yes |
| subnets | Public subnet IDs (at least two AZs) | `list(string)` | n/a | yes |
| vpc_id | VPC of the ALB | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns_name | ALB DNS name (the origin Cloudflare points to) |
<!-- END_TF_DOCS -->
