mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:111111111111:log-group:/aws/lambda/x" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/x" }
  }
  mock_resource "aws_lambda_function_url" {
    defaults = { function_url = "https://abc123.lambda-url.us-east-1.on.aws/" }
  }
}

variables {
  prefix      = "jonomait"
  environment = "production"
  name        = "web-english"
  source_dir  = "tests/fixture"
  handler     = "progress.handler"
}

run "private_function_behind_cloudfront" {
  command = plan

  assert {
    condition = (
      aws_lambda_function.this.function_name == "jonomait-prd-web-english-api" &&
      aws_iam_role.function.name == "jonomait-prd-use1-web-english-api" &&
      aws_lambda_function.this.architectures[0] == "arm64" &&
      aws_lambda_function_url.this.authorization_type == "AWS_IAM"
    )
    error_message = "<prefix>-<env>-<app>-api on Graviton, its URL behind IAM (only CloudFront signs requests)."
  }
}

run "only_its_own_logs_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy_attachment.extra) == 0 && aws_cloudwatch_log_group.function.retention_in_days == 30
    error_message = "Without policy_arns the role only writes its own logs, kept 30 days."
  }
}

run "the_data_access_policy_is_attached" {
  command = plan

  variables {
    policy_arns = ["arn:aws:iam::111111111111:policy/jonomait-prd-web-english-data-access"]
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.extra) == 1
    error_message = "The app's data-access policy goes to the function's role."
  }
}

run "unsupported_runtime_is_refused" {
  command = plan

  variables {
    runtime = "nodejs16.x"
  }

  expect_failures = [var.runtime]
}

run "reads_only_its_own_secrets" {
  command = plan

  variables {
    parameter_paths = ["/jonomait/production/web-english/secrets"]
  }

  assert {
    condition     = length(aws_iam_role_policy.parameters) == 1 && length(data.aws_iam_policy_document.parameters) == 1
    error_message = "With parameter_paths the role may read those paths (and nothing else in SSM)."
  }
}
