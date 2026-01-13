/*-----------------------+
 | AWS Resources Outputs |
 +-----------------------*/
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance (if assigned)"
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "The ID of the security group created by this module"
  value       = aws_security_group.this.id
}

output "iam_role_name" {
  description = "The name of the IAM role attached to the EC2 instance"
  value       = aws_iam_role.runner.name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to the EC2 instance"
  value       = aws_iam_role.runner.arn
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = aws_iam_instance_profile.this.name
}

/*-----------------------+
 | NAT Gateway Outputs    |
 +-----------------------*/
output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (only when create_network_infrastructure = true)"
  value       = local.create_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "nat_gateway_public_ip" {
  description = "The public IP of the NAT Gateway (only when create_network_infrastructure = true)"
  value       = local.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}
