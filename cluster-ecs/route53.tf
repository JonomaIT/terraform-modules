# Private zone with a wildcard to the internal ALB: <service>.<project>.internal resolves to it.
# The ".internal" TLD is reserved for private use (ICANN, 2024): it never collides with a public domain.
resource "aws_route53_zone" "private" {
  name    = format("%s.internal", var.project_name)
  comment = format("Private zone for %s (internal ALB)", var.project_name)

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "wildcard_internal" {
  zone_id = aws_route53_zone.private.zone_id
  name    = format("*.%s.internal", var.project_name)
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}
