# A queue and its dead-letter queue in every region of the app, same name. Optionally subscribed to
# SNS topics, whatever their region, so a message published in any region reaches every region
# (cross-region fan-out: if one region fails, the other already holds a copy of everything).
#
#   standby = false   every region's queue gets every region's topics (ADR-012, active/passive:
#                     the ACTIVE region processes everything)
#   standby = true    each region's queue gets only its own region's topics, and <name>-standby
#                     gets the copies from the other regions (ADR-013, active/active: each region
#                     processes what was born in it; the standby queue only while another region
#                     is out)
#
# A message that fails max_receive_count times moves to the dead-letter queue instead of looping.
# Long polling (20 s) by default: fewer empty receives, lower cost.

locals {
  split = var.standby && length(var.regions) > 1

  # One subscription per (queue region, topic): "<queue region>|<topic ARN>". With standby, a topic
  # of another region goes to the standby queue.
  subscriptions = {
    for pair in setproduct(var.regions, var.subscribe_topic_arns) : "${pair[0]}|${pair[1]}" => {
      queue_region = pair[0]
      topic_arn    = pair[1]
      topic_region = split(":", pair[1])[3]
      target       = local.split && split(":", pair[1])[3] != pair[0] ? "standby" : "main"
    }
  }

  # Queues that receive from topics, by key: the main queue under its region (as before standby
  # existed, so existing states do not move), the standby queue under "<region>/standby".
  receiving = merge(
    aws_sqs_queue.main,
    { for r, q in aws_sqs_queue.standby : "${r}/standby" => q },
  )
}

# SSE-SQS (keys managed by SQS): SNS can deliver to it, which an AWS managed KMS key (alias/aws/sqs)
# would refuse; a customer managed key would need grants per topic and region.
#trivy:ignore:AVD-AWS-0135
resource "aws_sqs_queue" "dlq" {
  for_each = toset(var.regions)

  region                    = each.value
  name                      = "${var.name}-dlq"
  message_retention_seconds = 1209600 # 14 days, the maximum: time to inspect and redrive
  sqs_managed_sse_enabled   = true
}

#trivy:ignore:AVD-AWS-0135
resource "aws_sqs_queue" "main" {
  for_each = toset(var.regions)

  region                     = each.value
  name                       = var.name
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.retention_days * 86400
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = var.max_receive_count
  })
}

# The copies from the other regions (standby = true): same settings and dead-letter queue.
#trivy:ignore:AVD-AWS-0135
resource "aws_sqs_queue" "standby" {
  for_each = local.split ? toset(var.regions) : toset([])

  region                     = each.value
  name                       = "${var.name}-standby"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.retention_days * 86400
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = var.max_receive_count
  })

  lifecycle {
    precondition {
      condition     = length(var.name) <= 72
      error_message = "With standby, name must be at most 72 characters (80 with the -standby suffix)."
    }
  }
}

# Only its own queues may move messages into a dead-letter queue.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  for_each = aws_sqs_queue.dlq

  region    = each.key
  queue_url = each.value.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = compact([aws_sqs_queue.main[each.key].arn, try(aws_sqs_queue.standby[each.key].arn, "")])
  })
}

data "aws_iam_policy_document" "queue" {
  for_each = local.receiving

  dynamic "statement" {
    for_each = length(var.subscribe_topic_arns) > 0 ? [1] : []

    content {
      sid       = "SubscribedTopicsOnly"
      actions   = ["sqs:SendMessage"]
      resources = [each.value.arn]

      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = var.subscribe_topic_arns
      }
    }
  }

  statement {
    sid       = "DenyWithoutTLS"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = [each.value.arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "main" {
  for_each = local.receiving

  region    = each.value.region
  queue_url = each.value.id
  policy    = data.aws_iam_policy_document.queue[each.key].json
}

# Raw delivery: the queue receives the published message itself, not an SNS envelope around it.
resource "aws_sns_topic_subscription" "main" {
  for_each = local.subscriptions

  region               = each.value.topic_region
  topic_arn            = each.value.topic_arn
  protocol             = "sqs"
  endpoint             = each.value.target == "standby" ? aws_sqs_queue.standby[each.value.queue_region].arn : aws_sqs_queue.main[each.value.queue_region].arn
  raw_message_delivery = true

  # The queue must accept the topic before the first message arrives.
  depends_on = [aws_sqs_queue_policy.main]
}
