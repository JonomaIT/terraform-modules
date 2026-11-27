# Smallest working use of the sns-topic module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//sns-topic?ref=sns-topic/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "order_created" {
  source = "../../"

  name    = "acme-stg-svc-orders-order-created"
  regions = ["us-east-1", "sa-east-1"]
}
