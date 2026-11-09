# Pattern consumed by apps with an API (deploy/api.hcl): a Lambda function behind the app's CloudFront
# distribution, at <host>/api/*. Its function URL only answers CloudFront (AWS_IAM: the distribution
# signs with its origin access control, granted by cloudfront-site), so there is no public endpoint.
# Who the caller is, the function checks itself (e.g. a session cookie it signed).

locals {
  env_short = { staging = "stg", production = "prd", "shared-services" = "shr" }[var.environment]
  full_name = "${var.prefix}-${local.env_short}-${var.name}-api"

  # IAM is global: the role name carries the region, as ecs-service does (us-east-1 → use1).
  region_parts = split("-", data.aws_region.current.region)
  region_short = "${local.region_parts[0]}${substr(local.region_parts[1], 0, 1)}${local.region_parts[length(local.region_parts) - 1]}"
  iam_name     = "${var.prefix}-${local.env_short}-${local.region_short}-${var.name}-api"
}

data "aws_region" "current" {}

# The code: every file of source_dir, zipped at plan time. A change in any file changes the hash
# and deploys a new version.
data "archive_file" "code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${local.full_name}.zip"
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function" {
  name               = local.iam_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${local.full_name}"
  retention_in_days = var.log_retention_days
}

# Logs only to its own group: nothing else unless policy_arns (the app's data-access policy) grants it.
data "aws_iam_policy_document" "logs" {
  statement {
    sid       = "OwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.function.arn}:*"]
  }
}

resource "aws_iam_role_policy" "logs" {
  name   = "own-logs"
  role   = aws_iam_role.function.id
  policy = data.aws_iam_policy_document.logs.json
}

data "aws_caller_identity" "current" {}

# Its secrets: read at run time, never in Terraform's state or the function's environment.
data "aws_iam_policy_document" "parameters" {
  count = length(var.parameter_paths) > 0 ? 1 : 0

  statement {
    sid       = "OwnSecrets"
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = flatten([for p in var.parameter_paths : ["arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${p}", "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${p}/*"]])
  }
}

resource "aws_iam_role_policy" "parameters" {
  count = length(var.parameter_paths) > 0 ? 1 : 0

  name   = "own-secrets"
  role   = aws_iam_role.function.id
  policy = data.aws_iam_policy_document.parameters[0].json
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.function.name
  policy_arn = each.value
}

# No X-Ray tracing: it bills per trace, and the platform's tracing (OpenTelemetry) comes later.
#trivy:ignore:AVD-AWS-0066
resource "aws_lambda_function" "this" {
  function_name    = local.full_name
  description      = "API of ${var.name} (${var.environment})"
  role             = aws_iam_role.function.arn
  handler          = var.handler
  runtime          = var.runtime
  architectures    = ["arm64"] # Graviton: about 20% cheaper per GB-second than x86
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  memory_size      = var.memory
  timeout          = var.timeout

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.function.name
  }

  depends_on = [aws_iam_role_policy.logs]
}

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "AWS_IAM"
}
