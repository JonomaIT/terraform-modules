# Smallest working use of the ecs-service module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//ecs-service?ref=ecs-service/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

# Finds the cluster, VPC, private subnets and shared ALB by the platform's naming convention
# (<prefix>-<environment>-...), so the platform must already exist in the account.
module "service" {
  source = "../../"

  prefix      = "acme"
  environment = "staging"
  name        = "svc-orders"
  image       = "111111111111.dkr.ecr.us-east-1.amazonaws.com/svc-orders:1.0.0"
  port        = 8080
  hosts       = ["orders"] # orders.<zone> on the shared ALB; leave empty for an internal service

  environment_variables = {
    LOG_LEVEL = "info"
  }
}
