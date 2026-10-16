# Shared, internet-facing ALB (ADR-001): apps attach a listener rule by host name. It only accepts
# HTTPS from var.ingress_cidrs (Cloudflare's ranges), so nobody reaches it around the WAF.
# There is no port 80 listener on purpose: Cloudflare redirects HTTP to HTTPS at the edge, and if
# that ever stops, HTTP fails here instead of crossing the internet unencrypted (fail closed).

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_region" "current" {}

resource "aws_security_group" "alb" {
  name_prefix = format("%s-", var.name)
  description = "Shared ALB: HTTPS from the allowed sources only, egress to the VPC"
  vpc_id      = var.vpc_id

  # A security group in use by a load balancer cannot be deleted: create the new one first.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.name
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = toset(var.ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = format("HTTPS from %s", each.value)
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "To targets inside the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

# Public on purpose: Cloudflare (WAF, DDoS, Access) is the front door, and the security group only
# accepts Cloudflare's ranges on 443.
#trivy:ignore:AVD-AWS-0053
resource "aws_lb" "main" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
}

# Until an app claims a host name, the answer is a 404 naming the ALB and its region: it shows
# which region served the request when testing multi-region routing.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # TLS 1.2 and 1.3 only
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = format("%s (%s): no app for this host", var.name, data.aws_region.current.region)
      status_code  = "404"
    }
  }
}
