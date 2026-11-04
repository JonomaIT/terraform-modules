# What the platform already runs in this account and region, found by naming convention
# (Padrões de nomes): no state of another component is read.

locals {
  env_short = { staging = "stg", production = "prd", "shared-services" = "shr" }[var.environment]

  # Short region for IAM names, for any region: us-east-1 → use1, sa-east-1 → sae1,
  # ap-southeast-2 → aps2.
  region_parts = split("-", data.aws_region.current.region)
  region_short = "${local.region_parts[0]}${substr(local.region_parts[1], 0, 1)}${local.region_parts[length(local.region_parts) - 1]}"

  base      = "${var.prefix}-${local.env_short}" # jonomait-stg
  full_name = "${local.base}-${var.name}"        # jonomait-stg-svc-compras
  namespace = "${var.prefix}.internal"
  public    = length(var.hosts) > 0

  # Parameters the platform publishes for every app of the environment (e.g. region-state).
  platform_parameters = "/${var.prefix}/${var.environment}/platform"

  # IAM is global: role names carry the region so the same app can run in two regions (ADR-008).
  iam_name = "${local.base}-${local.region_short}-${var.name}" # jonomait-stg-use1-svc-compras

  # Target group names are limited to 32 characters: shorten with a hash suffix when needed.
  tg_name = length(local.full_name) <= 32 ? local.full_name : "${substr(local.full_name, 0, 25)}-${substr(sha1(local.full_name), 0, 6)}"

  # ALB rules need a unique priority. Derived from the name, so nobody coordinates numbers; a
  # collision fails the apply with a clear AWS error (PriorityInUse) instead of hijacking a host.
  # 1-99 are reserved for the platform (e.g. the ingress health rule).
  priority = parseint(substr(sha1(var.name), 0, 8), 16) % 49900 + 100
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "main" {
  cluster_name = "${local.base}-ecs"
}

data "aws_vpc" "main" {
  tags = { Name = "${local.base}-network" }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = { Tier = "private" }
}

data "aws_lb" "shared" {
  count = local.public ? 1 : 0
  name  = "${local.base}-alb-shared"
}

data "aws_lb_listener" "https" {
  count             = local.public ? 1 : 0
  load_balancer_arn = data.aws_lb.shared[0].arn
  port              = 443
}
