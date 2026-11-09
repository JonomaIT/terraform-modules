# The site's certificate: always its own (all its names), issued by ACM in us-east-1 and validated
# by DNS in Cloudflare. Free, and it keeps every site independent: the platform's wildcard
# (*.<zone>) is issued by alb-shared, which only exists while the lab is up, so a site that used it
# could not be deployed without the lab (v0.16.0).

locals {
  zones = concat([var.zone], var.extra_zones)

  # Zone of each name: the longest zone it is in (a.b.com is in b.com, not in com).
  zones_by_length = [for s in reverse(sort([for z in local.zones : format("%03d|%s", length(z), z)])) : split("|", s)[1]]
  host_zone       = { for h in var.hosts : h => try([for z in local.zones_by_length : z if h == z || endswith(h, ".${z}")][0], null) }

  # Names this site may have (the same rule as app-dns): the platform zone's labels are open; its
  # apex and the names of an owned zone belong to the owner only. The apex is not covered by the
  # wildcard of the zone either way.
  not_allowed = [
    for h, z in local.host_zone : h
    if z != null && !(z == var.zone && h != var.zone) && lookup(var.zone_owners, z, h == var.zone ? "" : var.name) != var.name
  ]
}

resource "aws_acm_certificate" "site" {
  domain_name               = var.hosts[0]
  subject_alternative_names = slice(var.hosts, 1, length(var.hosts))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = alltrue([for h, z in local.host_zone : z != null])
      error_message = "Every host must be in the platform's zone (${var.zone}) or in one of extra_zones (${join(", ", var.extra_zones)})."
    }

    precondition {
      condition     = length(local.not_allowed) == 0
      error_message = "${join(", ", local.not_allowed)}: the zone (or the platform zone's apex) belongs to another app in zone_owners."
    }
  }
}

data "cloudflare_zone" "host" {
  for_each = toset([for z in values(local.host_zone) : z if z != null])

  filter = {
    name = each.value
  }
}

# Validation records: DNS only (never proxied), one per name. Keyed by the names (known at plan
# time); the record of each comes from the certificate, known only once it is requested.
locals {
  validation = { for o in aws_acm_certificate.site.domain_validation_options : o.domain_name => o }
}

resource "cloudflare_dns_record" "validation" {
  for_each = toset(var.hosts)

  zone_id = data.cloudflare_zone.host[local.host_zone[each.key]].id
  name    = trimsuffix(local.validation[each.key].resource_record_name, ".")
  type    = local.validation[each.key].resource_record_type
  content = trimsuffix(local.validation[each.key].resource_record_value, ".")
  proxied = false
  ttl     = 300
  comment = "owner: ${var.name}, ACM validation (managed by Terraform)"
}

resource "aws_acm_certificate_validation" "site" {
  certificate_arn = aws_acm_certificate.site.arn

  depends_on = [cloudflare_dns_record.validation]
}

locals {
  certificate_arn = aws_acm_certificate_validation.site.certificate_arn
}

# Up to v0.15.0 the certificate had a count (0 with the wildcard): sites deployed then keep theirs.
moved {
  from = aws_acm_certificate.site[0]
  to   = aws_acm_certificate.site
}

moved {
  from = aws_acm_certificate_validation.site[0]
  to   = aws_acm_certificate_validation.site
}
