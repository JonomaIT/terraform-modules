data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role: used by ECS itself to pull the image, write logs and read the secrets at start.
resource "aws_iam_role" "execution" {
  name               = "${local.iam_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  statement {
    sid       = "ReadOwnSecrets"
    actions   = ["secretsmanager:GetSecretValue", "ssm:GetParameters"]
    resources = distinct(values(var.secrets))
  }
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name   = "read-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.secrets[0].json
}

# Task role: what the app code itself can do in AWS. Only two things:
#   - read the platform's parameters of its environment, in its region (e.g. the region state,
#     ACTIVE or PASSIVE, ADR-012);
#   - whatever its data-access policy allows: created by the data runner from the app's
#     deploy/data.hcl, only on the app's own resources and the ones it declared it uses (ADR-011).
resource "aws_iam_role" "task" {
  name               = "${local.iam_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "platform" {
  statement {
    sid       = "ReadPlatformParameters"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.platform_parameters}/*"]
  }
}

resource "aws_iam_role_policy" "platform" {
  name   = "read-platform-parameters"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.platform.json
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = toset(var.task_policy_arns)

  role       = aws_iam_role.task.name
  policy_arn = each.value
}
