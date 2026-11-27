# cloudfront-site

**Kind:** pattern. Static site: private S3 bucket (versioned, old versions expire in 30 days) read only by CloudFront (OAC); managed cache and security-headers policies; GET/HEAD/OPTIONS only; optional SPA routing; reuses the platform's `*.<zone>` certificate (us-east-1). The public names come from `app-dns`.

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the cloudfront-site module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//cloudfront-site?ref=cloudfront-site/vX.Y.Z"

provider "aws" {
  region = "us-east-1" # CloudFront only takes ACM certificates from us-east-1
}

provider "cloudflare" {} # token from CLOUDFLARE_API_TOKEN

module "site" {
  source = "../../"

  prefix      = "acme"
  environment = "staging"
  name        = "web-shop"
  zone        = "example.com"
  hosts       = ["shop"] # shop.example.com
  spa         = true     # unknown paths answer index.html (client-side routing)
}
```

More in [`examples/`](examples/). Every release of this module is a tag `<module>/vX.Y.Z`, listed in [`CHANGELOG.md`](CHANGELOG.md).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| aws | >= 6.0 |
| cloudflare | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |
| cloudflare | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| api | The site's API: /api/* goes to this Lambda function URL, signed by the distribution. null = no API | ```object({ domain = string # host of the function URL (lambda-function url_domain) function_name = string })``` | `null` | no |
| environment | Account the site runs in (staging, production, shared-services) | `string` | n/a | yes |
| extra_zones | Other Cloudflare zones the platform allows names in (e.g. a customer's own domain). A site with a name there gets a certificate of its own, validated in Cloudflare | `list(string)` | `[]` | no |
| failover_region | Region of a replica of the bucket, read by CloudFront when the primary bucket fails (origin failover). null = one bucket | `string` | `null` | no |
| force_destroy | Allow destroying the bucket with files in it (labs); keep false where the files matter | `bool` | `false` | no |
| hosts | Public names of the site (CloudFront aliases): one label under zone, or names in extra_zones | `list(string)` | n/a | yes |
| name | App name = repo name (e.g. web-sales) | `string` | n/a | yes |
| prefix | Platform prefix (e.g. jonomait): every name starts with <prefix>-<env>-, the platform's parameters live under /<prefix>/<env>/platform | `string` | n/a | yes |
| price_class | CloudFront edge locations: PriceClass_100 (US, Canada, Europe; cheapest), _200, _All | `string` | `"PriceClass_100"` | no |
| spa | Single-page app: unknown paths return index.html with 200 | `bool` | `false` | no |
| zone | The platform's Cloudflare zone; its *.<zone> certificate (us-east-1) covers one-label names under it | `string` | n/a | yes |
| zone_owners | Zone => the app that owns it. The platform's zone listed here gives its apex to that app (one-label names stay open to every app); a zone in extra_zones listed here is that app's alone. A zone not listed keeps the old rule (any app) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket | Bucket the deploy uploads the site to |
| distribution_arn | Distribution ARN |
| distribution_id | CloudFront distribution (the deploy invalidates its cache) |
| domain_name | CloudFront address the public names point to (app-dns target) |
| failover_bucket | Copy of the bucket in failover_region: the deploy uploads to it too (null without failover) |
<!-- END_TF_DOCS -->
