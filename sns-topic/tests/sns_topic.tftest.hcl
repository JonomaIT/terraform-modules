mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  name    = "jonomait-prd-svc-vendas-pedido-criado"
  regions = ["us-east-1", "sa-east-1"]
}

run "one_encrypted_topic_per_region" {
  command = plan

  assert {
    condition     = toset(keys(aws_sns_topic.main)) == toset(["us-east-1", "sa-east-1"]) && aws_sns_topic.main["sa-east-1"].region == "sa-east-1"
    error_message = "One topic in each region of the app."
  }

  assert {
    condition     = alltrue([for t in aws_sns_topic.main : t.kms_master_key_id == "alias/aws/sns" && t.name == var.name])
    error_message = "Same name everywhere, encrypted at rest."
  }

  assert {
    condition     = length(aws_sns_topic_policy.main) == 2
    error_message = "Every topic gets the owner-only, TLS-only policy."
  }
}

run "fifo_names_are_rejected" {
  command = plan

  variables {
    name = "pedidos.fifo"
  }

  expect_failures = [var.name]
}
