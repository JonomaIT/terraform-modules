# Smallest working use of the alb module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//alb?ref=alb/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

data "cloudflare_ip_ranges" "edge" {}

module "alb" {
  source = "../../"

  name            = "acme-stg-alb-shared"
  vpc_id          = "vpc-0123456789abcdef0"
  subnets         = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/example"
  ingress_host    = "ingress-use1.stg.example.com"
  ingress_cidrs   = data.cloudflare_ip_ranges.edge.ipv4_cidrs # only Cloudflare reaches the ALB
}
