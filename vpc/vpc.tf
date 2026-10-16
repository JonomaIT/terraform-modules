# Subnets and route tables carry Tier = public | private, so other components find them by tag
# instead of reading this component's state.
resource "aws_vpc" "main" {
  cidr_block = var.cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.project_name
  }
}
