# Load balancer externo: entrada pública do cluster.
resource "aws_security_group" "lb" {
  name        = format("%s-loadbalancer", var.project_name)
  description = "Load balancer externo: HTTP/HTTPS da internet, saida so para a VPC"
  vpc_id      = var.vpc_id

  egress {
    description = "Saida para os targets dentro da VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.lb.id
  description       = "HTTP da internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "lb_https" {
  security_group_id = aws_security_group.lb.id
  description       = "HTTPS da internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "main" {
  name               = trimsuffix(substr(format("%s-ingress", var.project_name), 0, 32), "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name = format("%s-ingress", var.project_name)
  }
}

# Sem certificado ainda: só HTTP, com 404 padrão. Cada serviço pendura a sua listener rule.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
}
