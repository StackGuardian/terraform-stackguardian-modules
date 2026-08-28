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
  description = "Managed image the runner VM booted from - built by Packer, or the vm_image_id that was passed in"
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

output "subnet_id" {
  description = "Existing subnet the runner NIC was attached to"
  value       = data.azurerm_subnet.runner.id
}

output "ssh_command" {
  description = <<EOT
    Ready-to-use SSH command, once firewall.ssh_access_rules opens port 22.
    Falls back to the private IP when network.associate_public_ip is false, in
    which case you need a path into the subnet (VPN, bastion, ExpressRoute).
  EOT
  value       = "ssh ${var.firewall.admin_username}@${coalesce(module.azure_runner.vm_public_ip, module.azure_runner.vm_private_ip)}"
}

output "ssh_private_key" {
  description = "Generated SSH private key, when firewall.generate_ssh_key is true"
  value       = module.azure_runner.ssh_private_key
  sensitive   = true
}
