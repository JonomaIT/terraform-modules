mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:111111111111:test"
      url = "https://sqs.us-east-1.amazonaws.com/111111111111/test"
    }
  }
}

variables {
  name    = "jonomait-prd-svc-vendas-processamento"
  regions = ["us-east-1", "sa-east-1"]
  subscribe_topic_arns = [
    "arn:aws:sns:us-east-1:111111111111:jonomait-prd-svc-pedidos-pedido-criado",
    "arn:aws:sns:sa-east-1:111111111111:jonomait-prd-svc-pedidos-pedido-criado",
  ]
}

run "queue_and_dlq_per_region" {
  command = plan

  assert {
    condition     = toset(keys(aws_sqs_queue.main)) == toset(var.regions) && aws_sqs_queue.dlq["sa-east-1"].name == "jonomait-prd-svc-vendas-processamento-dlq"
    error_message = "One queue and one dead-letter queue in each region."
  }

  assert {
    condition     = alltrue([for q in aws_sqs_queue.main : q.sqs_managed_sse_enabled && q.receive_wait_time_seconds == 20 && q.message_retention_seconds == 4 * 86400])
    error_message = "Encrypted, long polling, 4 days of retention by default."
  }
}

run "every_queue_gets_every_region_topic" {
  command = plan

  assert {
    condition     = length(aws_sns_topic_subscription.main) == 4
    error_message = "2 queues × 2 topics: a message published in any region reaches every region."
  }

  assert {
    condition = alltrue([
      for k, s in aws_sns_topic_subscription.main : s.region == split(":", s.topic_arn)[3] && s.raw_message_delivery
    ])
    error_message = "A subscription lives in its topic's region and delivers the raw message."
  }
}

run "standby_splits_by_region" {
  command = plan

  variables {
    standby = true
  }

  assert {
    condition     = toset(keys(aws_sqs_queue.standby)) == toset(var.regions) && aws_sqs_queue.standby["us-east-1"].name == "jonomait-prd-svc-vendas-processamento-standby"
    error_message = "One standby queue per region, named <name>-standby."
  }

  assert {
    condition = alltrue([
      for k, s in local.subscriptions : s.target == (s.topic_region == s.queue_region ? "main" : "standby")
    ]) && length(aws_sns_topic_subscription.main) == 4
    error_message = "The own region's topic goes to the main queue, the other region's to the standby queue."
  }

  assert {
    condition     = length(aws_sqs_queue_policy.main) == 4 && length(output.standby_urls) == 2
    error_message = "Both queues of each region accept their topics, and the standby URLs are published."
  }
}

run "standby_needs_two_regions" {
  command = plan

  variables {
    standby              = true
    regions              = ["us-east-1"]
    subscribe_topic_arns = ["arn:aws:sns:us-east-1:111111111111:jonomait-prd-svc-pedidos-pedido-criado"]
  }

  assert {
    condition     = length(aws_sqs_queue.standby) == 0 && length(output.standby_urls) == 0
    error_message = "With one region there is no other region to stand by for."
  }
}

run "no_topics_no_subscriptions" {
  command = plan

  variables {
    subscribe_topic_arns = []
  }

  assert {
    condition     = length(aws_sns_topic_subscription.main) == 0
    error_message = "A plain queue subscribes to nothing."
  }
}

run "too_short_retention_is_rejected" {
  command = plan

  variables {
    retention_days = 0
  }

  expect_failures = [var.retention_days]
}
