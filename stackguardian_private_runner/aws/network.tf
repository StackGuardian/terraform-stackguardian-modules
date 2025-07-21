# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "this" {
  count = var.private_subnet_id != null ? 1 : 0

  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

# Create a NAT Gateway for internet access from private subnet
resource "aws_nat_gateway" "this" {
  count = var.private_subnet_id != null ? 1 : 0

  allocation_id = aws_eip.this[0].id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "${var.name_prefix}-nat-gateway"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "this" {
  count = var.private_subnet_id != null ? 1 : 0

  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = {
    Name = "${var.name_prefix}-private-route-table"
  }
}

# Associate the route table with the private subnet
resource "aws_route_table_association" "private_route_assoc" {
  count = var.private_subnet_id != null ? 1 : 0

  subnet_id      = var.private_subnet_id
  route_table_id = aws_route_table.this[0].id
}

# Security group for the EC2 instance (no SSH, only outbound)
resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-private-runner"
  description = "Block inboud and Allow All outbound for Private Runner."
  vpc_id      = var.vpc_id

  # Allow all ingress
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Allow SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["178.77.15.22/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
