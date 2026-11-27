# Smallest working use of the ecs-cluster module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//ecs-cluster?ref=ecs-cluster/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "cluster" {
  source = "../../"

  name      = "acme-stg-ecs"
  namespace = "acme.internal" # services find each other at <app>.acme.internal
  vpc_id    = "vpc-0123456789abcdef0"
}
