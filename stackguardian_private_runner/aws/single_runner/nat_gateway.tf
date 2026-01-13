# Optional NAT Gateway infrastructure for private subnet deployments
# Only created when create_network_infrastructure = true

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = local.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner-nat-eip"
  }
}

# NAT Gateway for private subnet internet access
resource "aws_nat_gateway" "this" {
  count         = local.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = var.network.public_subnet_id

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner-nat-gw"
  }

  depends_on = [aws_eip.nat]
}

# Route table for private subnet
resource "aws_route_table" "private" {
  count  = local.create_nat_gateway ? 1 : 0
  vpc_id = var.network.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner-rt"
  }
}

# Associate route table with private subnet
resource "aws_route_table_association" "private" {
  count          = local.create_nat_gateway ? 1 : 0
  subnet_id      = var.network.private_subnet_id
  route_table_id = aws_route_table.private[0].id
}
