# Smallest working use of the s3-bucket module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//s3-bucket?ref=s3-bucket/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "uploads" {
  source = "../../"

  name    = "acme-stg-svc-orders-uploads" # becomes acme-stg-svc-orders-uploads-<region>
  regions = ["us-east-1", "sa-east-1"]    # with replicate (default), both buckets see every object
}
