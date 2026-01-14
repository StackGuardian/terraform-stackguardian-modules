/*-----------------------+
 | ASG Outputs            |
 +-----------------------*/
output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group (created or existing)"
  value       = local.asg_name
}

output "launch_template_id" {
  description = "The ID of the Launch Template (only when create_asg = true)"
  value       = var.create_asg ? aws_launch_template.this[0].id : ""
}

output "launch_template_latest_version" {
  description = "The latest version of the Launch Template (only when create_asg = true)"
  value       = var.create_asg ? aws_launch_template.this[0].latest_version : 0
}

/*-----------------------+
 | Security Group Outputs |
 +-----------------------*/
output "security_group_id" {
  description = "The ID of the security group created by this module (only when create_asg = true)"
  value       = var.create_asg ? aws_security_group.this[0].id : ""
}

/*-----------------------+
 | IAM Outputs            |
 +-----------------------*/
output "iam_role_arn" {
  description = "The ARN of the EC2 IAM role (only when create_asg = true)"
  value       = var.create_asg ? aws_iam_role.runner[0].arn : ""
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile (only when create_asg = true)"
  value       = var.create_asg ? aws_iam_instance_profile.this[0].name : ""
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
