# External load balancer: public entry point of the cluster.
resource "aws_security_group" "lb" {
  name_prefix = format("%s-lb-", var.project_name)
  description = "External load balancer: HTTP/HTTPS from the internet, egress only to the VPC"
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

resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.lb.id
  description       = "HTTP from the internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "lb_https" {
  security_group_id = aws_security_group.lb.id
  description       = "HTTPS from the internet"
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

# No certificate yet: HTTP only. Until a service attaches its own listener rule, the default
# response is a 200 naming the project and region, which makes multi-region routing visible.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
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
