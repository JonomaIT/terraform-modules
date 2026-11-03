# The site's certificate. Names that are one label under the platform's zone are covered by the
# platform's wildcard (*.<zone>, issued by alb-shared). Any other name, such as a customer's own
# domain in one of extra_zones, makes the site issue a certificate of its own (all its names),
# validated by DNS in Cloudflare. The wildcard is only looked up when it is used, so such a site
# does not depend on the platform's ALB stack existing.

locals {
  zones = concat([var.zone], var.extra_zones)

  wildcard_covers = alltrue([for h in var.hosts : can(regex("^[a-z0-9-]+\\.${replace(var.zone, ".", "\\.")}$", h))])
  own_certificate = !local.wildcard_covers

  # Zone of each name: the longest zone it is in (a.b.com is in b.com, not in com).
  zones_by_length = [for s in reverse(sort([for z in local.zones : format("%03d|%s", length(z), z)])) : split("|", s)[1]]
  host_zone       = { for h in var.hosts : h => try([for z in local.zones_by_length : z if h == z || endswith(h, ".${z}")][0], null) }
}

data "aws_acm_certificate" "wildcard" {
  count = local.own_certificate ? 0 : 1

  domain      = "*.${var.zone}"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_acm_certificate" "site" {
  count = local.own_certificate ? 1 : 0

  domain_name               = var.hosts[0]
  subject_alternative_names = slice(var.hosts, 1, length(var.hosts))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = alltrue([for h, z in local.host_zone : z != null])
      error_message = "Every host must be in the platform's zone (${var.zone}) or in one of extra_zones (${join(", ", var.extra_zones)})."
    }
  }
}

data "cloudflare_zone" "host" {
  for_each = local.own_certificate ? toset([for z in values(local.host_zone) : z if z != null]) : toset([])

  filter = {
    name = each.value
  }
}

# Validation records: DNS only (never proxied), one per name. Keyed by the names (known at plan
# time); the record of each comes from the certificate, known only once it is requested.
locals {
  validation = local.own_certificate ? { for o in aws_acm_certificate.site[0].domain_validation_options : o.domain_name => o } : {}
}

resource "cloudflare_dns_record" "validation" {
  for_each = local.own_certificate ? toset(var.hosts) : toset([])

  zone_id = data.cloudflare_zone.host[local.host_zone[each.key]].id
  name    = trimsuffix(local.validation[each.key].resource_record_name, ".")
  type    = local.validation[each.key].resource_record_type
  content = trimsuffix(local.validation[each.key].resource_record_value, ".")
  proxied = false
  ttl     = 300
  comment = "owner: ${var.name}, ACM validation (managed by Terraform)"
}

resource "aws_acm_certificate_validation" "site" {
  count = local.own_certificate ? 1 : 0

  certificate_arn = aws_acm_certificate.site[0].arn

  depends_on = [cloudflare_dns_record.validation]
}

locals {
  certificate_arn = local.own_certificate ? aws_acm_certificate_validation.site[0].certificate_arn : data.aws_acm_certificate.wildcard[0].arn
}
