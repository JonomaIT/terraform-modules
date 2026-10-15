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

# Task role: what the app code itself can do in AWS. Nothing yet; data access will come from the
# <app>-data-access policy the infra team creates with the app's resources (ADR-004).
resource "aws_iam_role" "task" {
  name               = "${local.iam_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}
