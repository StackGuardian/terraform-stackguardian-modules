# Security group for the EC2 instances (only created when create_asg = true)
resource "aws_security_group" "this" {
  count = var.create_asg ? 1 : 0

  name        = "${local.effective_prefix}-private-runner-asg"
  description = "Block inbound (except SSH if provided) and Allow All outbound for Private Runner ASG."
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

  tags = {
    Name = "${local.effective_prefix}-private-runner-asg"
  }
}

# Allow runner security group to access VPC endpoints (STS, SSM, ECR, etc.)
resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  for_each = var.create_asg ? toset(var.network.vpc_endpoint_security_group_ids) : toset([])

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = each.value
  source_security_group_id = aws_security_group.this[0].id
  description              = "Allow HTTPS from Private Runner ASG"
}
