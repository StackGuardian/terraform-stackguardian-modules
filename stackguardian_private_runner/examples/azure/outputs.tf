/*---------------------------------+
 | Runner Group Outputs            |
 +---------------------------------*/
output "runner_group_name" {
  description = "The name of the StackGuardian runner group"
  value       = module.runner_group.runner_group_name
}

output "runner_group_url" {
  description = "Direct URL to the runner group in the StackGuardian web console"
  value       = module.runner_group.runner_group_url
}

output "azure_storage_account_name" {
  description = "The name of the Azure Storage Account used for the runner group storage backend"
  value       = module.runner_group.azure_storage_account_name
}

/*---------------------------------+
 | Runner VM Outputs               |
 +---------------------------------*/
output "vm_name" {
  description = "The name of the runner VM"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_public_ip" {
  description = "The public IP address of the runner VM"
  value       = azurerm_public_ip.this.ip_address
}

output "ssh_command" {
  description = "Ready-to-use SSH command to attach to the runner VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}"
}

/*---------------------------------+
 | Network Outputs                 |
 +---------------------------------*/
output "vnet_id" {
  description = "The ID of the created Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "subnet_id" {
  description = "The ID of the created Subnet"
  value       = azurerm_subnet.this.id
}
