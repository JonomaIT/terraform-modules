# Internal NLB in front of the internal ALB. It is the entry point for:
#   - API Gateway (REST) → VPC Link → NLB → internal ALB (REST VPC Links only accept an NLB as target)
#   - Global Accelerator → NLB → internal ALB (multi-region routing)
resource "aws_security_group" "vpc_link" {
  name_prefix = format("%s-vpc-link-", var.project_name)
  description = "VPC Link and Global Accelerator NLB: HTTP/HTTPS from the allowed sources and the VPC"
  vpc_id      = var.vpc_id

  egress {
    description = "Egress to the internal ALB"
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

# Allowed sources (var.ingress_cidrs) on var.ingress_ports, plus the VPC CIDR on 80 and 443.
# Global Accelerator traffic keeps the client IP (internet clients, or Cloudflare when the public
# name is proxied). The NLB itself is internal (no public IP): it is only reachable through Global
# Accelerator, the VPC Link or from inside the VPC.
resource "aws_vpc_security_group_ingress_rule" "vpc_link" {
  for_each = merge({
    for pair in setproduct(var.ingress_cidrs, var.ingress_ports) :
    "${pair[0]}-${pair[1]}" => { cidr = pair[0], port = pair[1] }
    }, {
    # The VPC always gets both ports: service-to-service traffic, NLB health checks, VPC Link.
    for port in [80, 443] :
    "${data.aws_vpc.main.cidr_block}-${port}" => { cidr = data.aws_vpc.main.cidr_block, port = port }
  })

  security_group_id = aws_security_group.vpc_link.id
  description       = format("Port %d from %s", each.value.port, each.value.cidr)
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
}

resource "aws_lb" "vpc_link" {
  name               = trimsuffix(substr(format("%s-vpc-link", var.project_name), 0, 32), "-")
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.vpc_link.id]
  subnets            = var.private_subnets

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = false

  # VPC Link traffic arrives through PrivateLink; without this the SG rules would not apply to it.
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"

  tags = {
    Name = format("%s-vpc-link", var.project_name)
  }
}

# ------------------------------------------------------------------ HTTP (80)
resource "aws_lb_target_group" "vpc_link" {
  name = trimsuffix(substr(format("%s-vpc-link", var.project_name), 0, 32), "-")

  # Destroy order: this target group (whose deletion drops the ALB registration immediately)
  # must go before the ALB listener it points at. Deregistering the attachment alone is not
  # enough: the ALB stays "draining" for the deregistration delay, and AWS refuses to delete the
  # listener meanwhile (ResourceInUse).
  depends_on  = [aws_lb_listener.http_internal]
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  target_health_state {
    enable_unhealthy_connection_termination = false
  }

  tags = {
    Name = format("%s-vpc-link", var.project_name)
  }
}

resource "aws_lb_listener" "vpc_link" {
  load_balancer_arn = aws_lb.vpc_link.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpc_link.arn
  }
}

resource "aws_lb_target_group_attachment" "internal_lb" {
  target_group_arn = aws_lb_target_group.vpc_link.arn
  target_id        = aws_lb.internal.arn
  port             = 80

  # The target is the ALB, not the listener, so Terraform does not link the two on its own.
  # AWS requires the ALB to have a listener on the registered port and refuses to delete
  # that listener while the ALB is someone's target. Without this edge, destroy tries to
  # delete the listener first and fails with ResourceInUse.
  depends_on = [aws_lb_listener.http_internal]
}

# ----------------------------------------------- HTTPS (443), only with certs
resource "aws_lb_target_group" "vpc_link_https" {
  count = length(var.acm_certs) > 0 ? 1 : 0

  name = trimsuffix(substr(format("%s-vpc-link-https", var.project_name), 0, 32), "-")

  # Same destroy-order reason as the HTTP target group above.
  depends_on  = [aws_lb_listener.https_internal]
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    protocol = "HTTPS"
    matcher  = "200-399"
  }

  target_health_state {
    enable_unhealthy_connection_termination = false
  }

  tags = {
    Name = format("%s-vpc-link-https", var.project_name)
  }
}

resource "aws_lb_listener" "vpc_link_https" {
  count = length(var.acm_certs) > 0 ? 1 : 0

  load_balancer_arn = aws_lb.vpc_link.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpc_link_https[0].arn
  }
}

resource "aws_lb_target_group_attachment" "internal_lb_https" {
  count = length(var.acm_certs) > 0 ? 1 : 0

  target_group_arn = aws_lb_target_group.vpc_link_https[0].arn
  target_id        = aws_lb.internal.arn
  port             = 443

  # Same ordering reason as the HTTP attachment above.
  depends_on = [aws_lb_listener.https_internal]
}

# ------------------------------------------------------------ API Gateway
resource "aws_api_gateway_vpc_link" "main" {
  name        = format("%s-vpc-link", var.project_name)
  description = format("API Gateway VPC Link to the internal NLB of %s", var.project_name)
  target_arns = [aws_lb.vpc_link.arn]
}

# v0.3.x → v0.4.0: the rules became one per (source, port).
moved {
  from = aws_vpc_security_group_ingress_rule.vpc_link_http
  to   = aws_vpc_security_group_ingress_rule.vpc_link["0.0.0.0/0-80"]
}

moved {
  from = aws_vpc_security_group_ingress_rule.vpc_link_https
  to   = aws_vpc_security_group_ingress_rule.vpc_link["0.0.0.0/0-443"]
}
