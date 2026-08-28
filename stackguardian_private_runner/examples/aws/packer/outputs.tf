output "ami_id" {
  description = "AMI built by Packer and recorded in state"
  value       = module.packer.ami_id
}

output "ami_info" {
  description = "AMI metadata: region, OS, name pattern, deregistration protection and cleanup settings"
  value       = module.packer.ami_info
}

output "cleanup_commands" {
  description = "Ready-to-run AWS CLI commands for inspecting and removing the AMI by hand"
  value       = module.packer.cleanup_commands
}

output "subnet_id" {
  description = "Existing subnet the build instance ran in"
  value       = data.aws_subnet.build.id
}
