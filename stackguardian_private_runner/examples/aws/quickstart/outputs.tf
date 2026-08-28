/*---------------------------------+
 | Runner Group Outputs            |
 +---------------------------------*/
output "runner_group_name" {
  description = "StackGuardian runner group name"
  value       = module.runner_group.runner_group_name
}

output "runner_group_url" {
  description = "URL to the runner group in the StackGuardian console"
  value       = module.runner_group.runner_group_url
}

output "connector_name" {
  description = "StackGuardian connector name"
  value       = module.runner_group.connector_name
}

output "s3_bucket_name" {
  description = "S3 bucket used for storage backend"
  value       = module.runner_group.s3_bucket_name
}

/*---------------------------------+
 | AMI Outputs                     |
 +---------------------------------*/
output "ami_id" {
  description = "AMI the runner booted from - built by Packer, or the ami_id that was passed in"
  value       = module.packer.ami_id
}

/*---------------------------------+
 | Runner Instance Outputs         |
 +---------------------------------*/
output "instance_id" {
  description = "EC2 instance ID of the private runner"
  value       = module.single_runner.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the private runner instance"
  value       = module.single_runner.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP of the private runner instance"
  value       = module.single_runner.instance_private_ip
}

output "security_group_id" {
  description = "Security group ID of the private runner"
  value       = module.single_runner.security_group_id
}

output "subnet_id" {
  description = "Existing subnet the runner was placed in"
  value       = data.aws_subnet.runner.id
}

output "ssh_command" {
  description = <<EOT
    Ready-to-use SSH command, once firewall.ssh_access_rules opens port 22.
    Falls back to the private IP when network.associate_public_ip is false, in
    which case reach the instance over Session Manager or from inside the VPC.
  EOT
  value       = "ssh ${local.ssh_username}@${coalesce(module.single_runner.instance_public_ip, module.single_runner.instance_private_ip)}"
}
