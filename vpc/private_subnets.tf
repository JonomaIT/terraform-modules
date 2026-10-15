resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = var.private_subnets[count.index].availability_zone

  tags = {
    Name = var.private_subnets[count.index].name
    Tier = "private"
  }
}

locals {
  # One NAT Gateway per AZ (resilient) or a single one in the first public subnet (cheaper: every
  # private subnet loses internet egress if that AZ fails).
  nat_subnets = var.single_nat_gateway ? slice(var.public_subnets, 0, 1) : var.public_subnets
}

resource "aws_eip" "eip" {
  count  = length(local.nat_subnets)
  domain = "vpc"

  tags = {
    Name = format("%s-nat-%s", var.project_name, local.nat_subnets[count.index].availability_zone)
  }
}

resource "aws_nat_gateway" "private" {
  count = length(local.nat_subnets)

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = format("%s-nat-%s", var.project_name, local.nat_subnets[count.index].availability_zone)
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-private-%s", var.project_name, var.private_subnets[count.index].availability_zone)
    Tier = "private"
  }
}

resource "aws_route" "private" {
  count = length(var.private_subnets)

  destination_cidr_block = "0.0.0.0/0"

  route_table_id = aws_route_table.private[count.index].id

  # Single NAT: everyone uses it. Per AZ: the NAT in the same AZ as the private subnet, matched by
  # AZ name (not by list position).
  nat_gateway_id = aws_nat_gateway.private[
    var.single_nat_gateway ? 0 : index(var.public_subnets[*].availability_zone, var.private_subnets[count.index].availability_zone)
  ].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
