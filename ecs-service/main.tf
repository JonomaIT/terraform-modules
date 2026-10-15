# Pattern consumed by apps: an ECS service on the platform cluster, with logs, autoscaling,
# Service Connect (<name>.jonomait.internal) and, when the app has public hosts, a target group
# and a host rule on the shared ALB.

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.full_name}"
  retention_in_days = 30
}

resource "aws_security_group" "app" {
  name_prefix = "${local.full_name}-"
  description = "Tasks of ${var.name}: app port from the shared ALB and the VPC (Service Connect)"
  vpc_id      = data.aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = local.full_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  count = local.public ? 1 : 0

  security_group_id            = aws_security_group.app.id
  description                  = "App port from the shared ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  referenced_security_group_id = one(data.aws_lb.shared[0].security_groups)
}

resource "aws_vpc_security_group_ingress_rule" "from_vpc" {
  security_group_id = aws_security_group.app.id
  description       = "App port from other services in the VPC (Service Connect)"
  ip_protocol       = "tcp"
  from_port         = var.port
  to_port           = var.port
  cidr_ipv4         = data.aws_vpc.main.cidr_block
}

# Image pulls, AWS APIs and external calls (through the NAT Gateway).
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_ecs_task_definition" "app" {
  family                   = local.full_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image
    essential = true

    portMappings = [{
      name          = "http"
      containerPort = var.port
      protocol      = "tcp"
      appProtocol   = "http"
    }]

    environment = [for k, v in var.environment_variables : { name = k, value = v }]
    secrets     = [for k, v in var.secrets : { name = k, valueFrom = v }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = var.name
      }
    }
  }])
}

resource "aws_lb_target_group" "app" {
  count = local.public ? 1 : 0

  name                 = local.tg_name
  port                 = var.port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.main.id
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "app" {
  count = local.public ? 1 : 0

  listener_arn = data.aws_lb_listener.https[0].arn
  priority     = local.priority

  condition {
    host_header {
      values = var.hosts
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = data.aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.min_capacity

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = local.public ? [1] : []

    content {
      target_group_arn = aws_lb_target_group.app[0].arn
      container_name   = var.name
      container_port   = var.port
    }
  }

  # A deployment whose tasks never get healthy is rolled back to the last working one, and the
  # apply fails instead of reporting success.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  wait_for_steady_state = true

  service_connect_configuration {
    enabled   = true
    namespace = data.aws_ecs_cluster.main.service_connect_defaults[0].namespace

    service {
      port_name      = "http"
      discovery_name = var.name

      client_alias {
        port     = var.port
        dns_name = "${var.name}.${local.namespace}"
      }
    }
  }

  propagate_tags = "SERVICE"

  # Autoscaling owns the task count after the first apply.
  lifecycle {
    ignore_changes = [desired_count]
  }

  # The target group must be attached to a listener before a service can use it.
  depends_on = [aws_lb_listener_rule.app]
}

resource "aws_appautoscaling_target" "app" {
  service_namespace  = "ecs"
  resource_id        = "service/${data.aws_ecs_cluster.main.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.full_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.app.service_namespace
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_target

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
