# External load balancer: internet-facing entry point of the cluster (optional).
resource "aws_security_group" "lb" {
  count = var.external_lb_enabled ? 1 : 0

  name_prefix = format("%s-lb-", var.project_name)
  description = "External load balancer: HTTP/HTTPS from the allowed sources, egress only to the VPC"
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

resource "aws_vpc_security_group_ingress_rule" "lb" {
  for_each = var.external_lb_enabled ? {
    for pair in setproduct(var.ingress_cidrs, var.ingress_ports) : "${pair[0]}-${pair[1]}" => { cidr = pair[0], port = pair[1] }
  } : {}

  security_group_id = aws_security_group.lb[0].id
  description       = format("Port %d from %s", each.value.port, each.value.cidr)
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
}

resource "aws_lb" "main" {
  count = var.external_lb_enabled ? 1 : 0

  name               = trimsuffix(substr(format("%s-ingress", var.project_name), 0, 32), "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb[0].id]
  subnets            = var.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name = format("%s-ingress", var.project_name)
  }
}

# No certificate yet: HTTP only. Until a service attaches its own listener rule, the default
# response is a 200 naming the project and region, which makes multi-region routing visible.
resource "aws_lb_listener" "http" {
  count = var.external_lb_enabled ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = format("%s - %s", var.project_name, data.aws_region.current.region)
      status_code  = "200"
    }
  }
}

# v0.3.x → v0.4.0: the external ALB became optional (count) and its rules follow ingress_cidrs.
moved {
  from = aws_security_group.lb
  to   = aws_security_group.lb[0]
}

moved {
  from = aws_lb.main
  to   = aws_lb.main[0]
}

moved {
  from = aws_lb_listener.http
  to   = aws_lb_listener.http[0]
}

moved {
  from = aws_vpc_security_group_ingress_rule.lb_http
  to   = aws_vpc_security_group_ingress_rule.lb["0.0.0.0/0-80"]
}

moved {
  from = aws_vpc_security_group_ingress_rule.lb_https
  to   = aws_vpc_security_group_ingress_rule.lb["0.0.0.0/0-443"]
}
