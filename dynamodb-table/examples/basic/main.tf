# Smallest working use of the dynamodb-table module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//dynamodb-table?ref=dynamodb-table/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "orders" {
  source = "../../"

  name     = "acme-stg-svc-orders-orders"
  regions  = ["us-east-1", "sa-east-1"] # first region holds the global table, the rest are replicas
  hash_key = "order_id"

  deletion_protection = false # labs only
}
