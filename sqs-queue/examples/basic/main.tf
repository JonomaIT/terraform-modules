# Smallest working use of the sqs-queue module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//sqs-queue?ref=sqs-queue/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "billing" {
  source = "../../"

  name    = "acme-stg-svc-billing-orders"
  regions = ["us-east-1", "sa-east-1"]

  # every region's queue gets the messages published in every region
  subscribe_topic_arns = [
    "arn:aws:sns:us-east-1:111111111111:acme-stg-svc-orders-order-created",
    "arn:aws:sns:sa-east-1:111111111111:acme-stg-svc-orders-order-created",
  ]
}
