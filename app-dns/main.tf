# Pattern consumed by apps (ADR-010): the app's public names, created and removed with the app.
# Each one is a proxied CNAME to the environment's entry (ingress), which the platform owns and
# which routes to a healthy region; the shared ALB then routes the host to the app. A static site
# points its names at its CloudFront distribution instead.
#
# Names are one label under the platform's zone, or in one of extra_zones (zones the platform
# allows, e.g. a customer's own domain), where the zone's apex is allowed too (a proxied CNAME at
# the apex: Cloudflare flattens it).
#
# Guardrails:
#   - only <label>.<zone> names (Universal SSL covers one level), never a reserved label;
#   - every record carries its owner in the comment, and a name that already exists with another
#     owner is refused at plan time: an app cannot take over another app's name.

locals {
  comment = "owner: ${var.owner} (managed by Terraform)"

  # Zone of each name: the longest zone it is in.
  zones           = concat([var.zone], var.extra_zones)
  zones_by_length = [for s in reverse(sort([for z in local.zones : format("%03d|%s", length(z), z)])) : split("|", s)[1]]
  host_zone       = { for h in var.hosts : h => [for z in local.zones_by_length : z if h == z || endswith(h, ".${z}")][0] }
}

data "cloudflare_zone" "zone" {
  for_each = toset(values(local.host_zone))

  filter = {
    name = each.value
  }
}

data "cloudflare_dns_records" "existing" {
  for_each = toset(var.hosts)

  zone_id = data.cloudflare_zone.zone[local.host_zone[each.value]].id
  name = {
    exact = each.value
  }
}

resource "cloudflare_dns_record" "app" {
  for_each = toset(var.hosts)

  zone_id = data.cloudflare_zone.zone[local.host_zone[each.value]].id
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
