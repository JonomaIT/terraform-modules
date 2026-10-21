# An SNS topic in every region of the app, same name: the app publishes in its own region, and
# consumers (sqs-queue) subscribe to the topic of every region, so a message published anywhere
# reaches every region.
#
# Only the account itself may use the topic, and only over TLS.

data "aws_caller_identity" "current" {}

# Encrypted with the AWS managed key (alias/aws/sns): SNS decrypts it before delivering, so any
# queue can subscribe. A customer managed key would need a key per region and grants on every
# queue for nothing more.
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "main" {
  for_each = toset(var.regions)

  region            = each.value
  name              = var.name
  kms_master_key_id = "alias/aws/sns"
}

data "aws_iam_policy_document" "topic" {
  for_each = aws_sns_topic.main

  statement {
    sid = "OwnerAccountOnly"
    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:Subscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
    ]
    resources = [each.value.arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "DenyWithoutTLS"
    effect    = "Deny"
    actions   = ["sns:Publish"]
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

resource "aws_sns_topic_policy" "main" {
  for_each = aws_sns_topic.main

  region = each.key
  arn    = each.value.arn
  policy = data.aws_iam_policy_document.topic[each.key].json
}
