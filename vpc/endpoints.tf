# Gateway endpoints: traffic from the private subnets to S3 and DynamoDB (image layers from ECR
# included, they live in S3) stays on the AWS network instead of going through the NAT Gateway.
# They are free and remove the NAT data processing charge for that traffic.
data "aws_region" "current" {}

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(var.gateway_endpoints)

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = {
    Name = "${var.project_name}-${each.value}"
  }
}
