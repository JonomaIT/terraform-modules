# Smallest working use of the lambda-function module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//lambda-function?ref=lambda-function/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "api" {
  source = "../../"

  prefix      = "acme"
  environment = "staging"
  name        = "web-shop"
  source_dir  = "${path.module}/api" # api/index.mjs exports handler
  handler     = "index.handler"
}
