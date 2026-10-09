# API Gateway (REST) → VPC Link → NLB interno → ALB interno.
# O VPC Link do API Gateway REST só aceita NLB como alvo, por isso o NLB na frente do ALB.
resource "aws_security_group" "vpc_link" {
  name        = format("%s-vpc-link", var.project_name)
  description = "NLB do VPC Link: HTTP/HTTPS de dentro da VPC (inclui o trafego do API Gateway)"
  vpc_id      = var.vpc_id

  egress {
    description = "Saida para o ALB interno"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_link_http" {
  security_group_id = aws_security_group.vpc_link.id
  description       = "HTTP de dentro da VPC"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "vpc_link_https" {
  security_group_id = aws_security_group.vpc_link.id
  description       = "HTTPS de dentro da VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

resource "aws_lb" "vpc_link" {
  name               = trimsuffix(substr(format("%s-vpc-link", var.project_name), 0, 32), "-")
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.vpc_link.id]
  subnets            = var.private_subnets

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = false

  # O tráfego do VPC Link chega por PrivateLink; sem isto as regras do SG não valeriam para ele.
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"

  tags = {
    Name = format("%s-vpc-link", var.project_name)
  }
}

resource "aws_lb_target_group" "vpc_link" {
  name        = trimsuffix(substr(format("%s-vpc-link", var.project_name), 0, 32), "-")
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

  # O alvo é o ALB, não o listener, então o Terraform não liga os dois sozinho.
  # A AWS exige que o ALB tenha listener na porta registrada, e recusa remover
  # esse listener enquanto o ALB for alvo de alguém — sem esta aresta o destroy
  # tenta apagar o listener primeiro e falha com ResourceInUse.
  depends_on = [aws_lb_listener.http_internal]
}

resource "aws_api_gateway_vpc_link" "main" {
  name        = format("%s-vpc-link", var.project_name)
  description = format("VPC Link do API Gateway para o NLB interno de %s", var.project_name)
  target_arns = [aws_lb.vpc_link.arn]
}
