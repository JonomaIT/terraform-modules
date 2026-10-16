# Pattern consumed by apps (ADR-010): the app's public names, created and removed with the app.
# Each one is a proxied CNAME to the environment's entry (ingress), which the platform owns and
# which routes to a healthy region; the shared ALB then routes the host to the app.
#
# Guardrails:
#   - only <label>.<zone> names (Universal SSL covers one level), never a reserved label;
#   - every record carries its owner in the comment, and a name that already exists with another
#     owner is refused at plan time: an app cannot take over another app's name.

locals {
  comment = "owner: ${var.owner} (managed by Terraform)"
}

data "cloudflare_zone" "main" {
  filter = {
    name = var.zone
  }
}

data "cloudflare_dns_records" "existing" {
  for_each = toset(var.hosts)

  zone_id = data.cloudflare_zone.main.id
  name = {
    exact = each.value
  }
}

resource "cloudflare_dns_record" "app" {
  for_each = toset(var.hosts)

  zone_id = data.cloudflare_zone.main.id
  name    = each.value
  type    = "CNAME"
  content = var.target
  proxied = true
  ttl     = 1 # automatic; mandatory when proxied
  comment = local.comment

  lifecycle {
    precondition {
      condition     = alltrue([for r in data.cloudflare_dns_records.existing[each.value].result : r.comment == local.comment])
      error_message = "${each.value} already exists in Cloudflare and belongs to someone else (its comment is not \"${local.comment}\")."
    }
  }
}
