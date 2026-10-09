# Load balancer interno: tráfego entre serviços e entrada do VPC Link (via NLB).
# Só aceita origem de dentro da VPC.
resource "aws_security_group" "lb_internal" {
  name        = format("%s-loadbalancer-internal", var.project_name)
  description = "Load balancer interno: HTTP/HTTPS so de dentro da VPC"
  vpc_id      = var.vpc_id

  egress {
    description = "Saida para os targets dentro da VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_internal_http" {
  security_group_id = aws_security_group.lb_internal.id
  description       = "HTTP de dentro da VPC"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "lb_internal_https" {
  security_group_id = aws_security_group.lb_internal.id
  description       = "HTTPS de dentro da VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.main.cidr_block
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
      message_body = "404: Not Found (Internal Load Balancer)"
      status_code  = "404"
    }
  }
}
