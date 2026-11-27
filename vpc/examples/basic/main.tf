# Smallest working use of the vpc module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=vpc/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../"

  project_name       = "acme-stg-network"
  cidr               = "10.10.0.0/16"
  single_nat_gateway = true # one NAT for the whole VPC: cheaper, fine outside production

  public_subnets = [
    { name = "public-a", cidr = "10.10.0.0/24", availability_zone = "us-east-1a" },
    { name = "public-b", cidr = "10.10.1.0/24", availability_zone = "us-east-1b" },
  ]
  private_subnets = [
    { name = "private-a", cidr = "10.10.10.0/24", availability_zone = "us-east-1a" },
    { name = "private-b", cidr = "10.10.11.0/24", availability_zone = "us-east-1b" },
  ]
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
