# Zona privada com wildcard para o ALB interno: <servico>.<project>.internal resolve para ele.
# TLD ".internal" é reservado para uso privado (ICANN, 2024): não colide com nenhum domínio público.
resource "aws_route53_zone" "private" {
  name    = format("%s.internal", var.project_name)
  comment = format("Zona privada de %s (ALB interno)", var.project_name)

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
