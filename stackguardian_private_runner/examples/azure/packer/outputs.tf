output "image_id" {
  description = "Managed image built by Packer and recorded in state"
  value       = module.packer.image_id
}

output "image_info" {
  description = "Image metadata: location, resource group, OS, name and cleanup settings"
  value       = module.packer.image_info
}

output "resource_group_name" {
  description = "Resource group holding the managed image"
  value       = module.packer.resource_group_name
}

output "cleanup_commands" {
  description = "Ready-to-run az CLI commands for inspecting and removing the image by hand"
  value       = module.packer.cleanup_commands
}
