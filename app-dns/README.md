# app-dns

**Kind:** pattern. The app's public names (ADR-010): proxied CNAMEs to the environment's entry (`ingress`), created and removed with the app. Refuses reserved names (`ingress*`, `www`), names more than one level deep and names that already exist with another owner (record comment).

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the app-dns module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//app-dns?ref=app-dns/vX.Y.Z"

provider "cloudflare" {} # token from CLOUDFLARE_API_TOKEN

module "dns" {
  source = "../../"

  zone   = "example.com"
  hosts  = ["orders"]                # orders.example.com
  target = "ingress.stg.example.com" # the environment's entry, owned by the platform
  owner  = "svc-orders"              # written in the record comment; another owner is refused
}
```

More in [`examples/`](examples/). Every release of this module is a tag `<module>/vX.Y.Z`, listed in [`CHANGELOG.md`](CHANGELOG.md).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| cloudflare | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| cloudflare | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| extra_zones | Other zones the platform allows names in (e.g. a customer's own domain): the apex or one label under it | `list(string)` | `[]` | no |
| hosts | Public names of the app: <label>.<zone>, the platform zone's apex when zone_owners gives it to this app, or the apex or <label>.<z> of a zone in extra_zones | `list(string)` | n/a | yes |
| owner | App that owns the names (the repo name); written in the record comment | `string` | n/a | yes |
| target | Entry of the environment the names point to (e.g. ingress.jonoma.com.br) | `string` | n/a | yes |
| zone | Cloudflare zone (e.g. jonoma.com.br) | `string` | n/a | yes |
| zone_owners | Zone => the app that owns it. The platform's zone listed here gives its apex to that app (one-label names stay open to every app); a zone in extra_zones listed here is that app's alone. A zone not listed keeps the old rule (any app) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| names | Public names created for the app |
<!-- END_TF_DOCS -->
