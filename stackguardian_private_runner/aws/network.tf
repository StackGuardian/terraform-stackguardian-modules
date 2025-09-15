# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "this" {
  count = var.network.private_subnet_id != "" && var.network.create_network_infrastructure ? 1 : 0

  domain = "vpc"
  tags = {
    Name = "${var.override_names.global_prefix}-nat-eip"
  }
}

# Create a NAT Gateway for internet access from private subnet
resource "aws_nat_gateway" "this" {
  count = var.network.private_subnet_id != "" && var.network.create_network_infrastructure ? 1 : 0

  allocation_id = aws_eip.this[0].id
  subnet_id     = var.network.public_subnet_id

  tags = {
    Name = "${var.override_names.global_prefix}-nat-gateway"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "this" {
  count = var.network.private_subnet_id != "" && var.network.create_network_infrastructure ? 1 : 0

  vpc_id = var.network.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = {
    Name = "${var.override_names.global_prefix}-private-route-table"
  }
}

# Associate the route table with the private subnet
resource "aws_route_table_association" "private_route_assoc" {
  count = var.network.private_subnet_id != "" && var.network.create_network_infrastructure ? 1 : 0

  subnet_id      = var.network.private_subnet_id
  route_table_id = aws_route_table.this[0].id
}

# Security group for the EC2 instance (no SSH, only outbound)
resource "aws_security_group" "this" {
  name        = "${var.override_names.global_prefix}-private-runner"
  description = "Block inboud and Allow All outbound for Private Runner."
  vpc_id      = var.network.vpc_id

  # Allow SSH (only if SSH access rules are provided)
  dynamic "ingress" {
    for_each = var.firewall.ssh_access_rules
    content {
      description = "SSH-${ingress.key}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Additional ingress rules
  dynamic "ingress" {
    for_each = var.firewall.additional_ingress_rules
    content {
      description = ingress.key
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
