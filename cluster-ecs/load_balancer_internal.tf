# Internal load balancer: service-to-service traffic and the VPC Link / Global Accelerator entry
# point (through the NLB).
resource "aws_security_group" "lb_internal" {
  name_prefix = format("%s-lb-internal-", var.project_name)
  description = "Internal load balancer: HTTP/HTTPS from the NLB clients and the VPC"
  vpc_id      = var.vpc_id

  egress {
    description = "Egress to targets inside the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # A security group in use by a load balancer cannot be deleted: create the new one first.
  lifecycle {
    create_before_destroy = true
  }
}

# Open to any source on purpose: the NLB target group (type alb) preserves the client IP, so
# requests coming through Global Accelerator reach this ALB with internet source addresses.
# Restricting to the VPC CIDR silently drops them (health checks still pass, since they come
# from the NLB). The ALB itself is internal (no public IP): it is only reachable through the
# NLB, from inside the VPC or over the peering.
resource "aws_vpc_security_group_ingress_rule" "lb_internal_http" {
  security_group_id = aws_security_group.lb_internal.id
  description       = "HTTP from NLB clients (client IP preserved) and the VPC"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "lb_internal_https" {
  security_group_id = aws_security_group.lb_internal.id
  description       = "HTTPS from NLB clients (client IP preserved) and the VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "internal" {
  name               = trimsuffix(substr(format("%s-internal", var.project_name), 0, 32), "-")
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_internal.id]
  subnets            = var.private_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name = format("%s-internal", var.project_name)
  }
}

resource "aws_lb_listener" "http_internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = format("%s - %s (internal)", var.project_name, data.aws_region.current.region)
      status_code  = "200"
    }
  }
}

# HTTPS only when certificates are given: the first one is the listener default,
# the others are attached as additional certificates (SNI).
resource "aws_lb_listener" "https_internal" {
  count = length(var.acm_certs) > 0 ? 1 : 0

  load_balancer_arn = aws_lb.internal.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certs[0]

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = format("%s - %s (internal)", var.project_name, data.aws_region.current.region)
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_certificate" "https_internal" {
  for_each = toset(slice(var.acm_certs, min(1, length(var.acm_certs)), length(var.acm_certs)))

  listener_arn    = aws_lb_listener.https_internal[0].arn
  certificate_arn = each.value
}
