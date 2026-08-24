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

output "resource_group_name" {
  description = "Resource group holding the storage backend, image, and runner VM"
  value       = module.runner_group.azure_resource_group_name
}

output "storage_account_name" {
  description = "Storage account used for the storage backend"
  value       = module.runner_group.azure_storage_account_name
}

/*---------------------------------+
 | Managed Identity Outputs        |
 +---------------------------------*/
output "storage_backend_identity_id" {
  description = "Resource ID of the managed identity the runner uses for storage backend access"
  value       = azurerm_user_assigned_identity.storage_backend.id
}

output "storage_backend_identity_principal_id" {
  description = "Principal ID of that managed identity - use it to create the role assignment out of band when create_role_assignments = false"
  value       = azurerm_user_assigned_identity.storage_backend.principal_id
}

/*---------------------------------+
 | Image Outputs                   |
 +---------------------------------*/
output "image_id" {
  description = "Managed image built by Packer and recorded in state"
  value       = module.packer.image_id
}

/*---------------------------------+
 | Runner VM Outputs               |
 +---------------------------------*/
output "vm_id" {
  description = "Resource ID of the private runner VM"
  value       = module.azure_runner.vm_id
}

output "vm_name" {
  description = "Name of the private runner VM"
  value       = module.azure_runner.vm_name
}

output "vm_public_ip" {
  description = "Public IP of the private runner VM"
  value       = module.azure_runner.vm_public_ip
}

output "vm_private_ip" {
  description = "Private IP of the private runner VM"
  value       = module.azure_runner.vm_private_ip
}

output "network_security_group_id" {
  description = "NSG ID of the private runner VM"
  value       = module.azure_runner.network_security_group_id
}

output "ssh_command" {
  description = "Ready-to-use SSH command, once firewall.ssh_access_rules opens port 22"
  value       = "ssh ${var.firewall.admin_username}@${module.azure_runner.vm_public_ip}"
}

output "ssh_private_key" {
  description = "Generated SSH private key, when firewall.generate_ssh_key is true"
  value       = module.azure_runner.ssh_private_key
  sensitive   = true
}
