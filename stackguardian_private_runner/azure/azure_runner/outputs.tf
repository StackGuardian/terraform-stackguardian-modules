/*-----------------------+
 | VM Resource Outputs   |
 +-----------------------*/
output "vm_id" {
  description = "The ID of the Azure Linux Virtual Machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "The name of the Azure Linux Virtual Machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "vm_public_ip" {
  description = "The public IP address of the VM (if assigned)"
  value       = var.network.associate_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

/*-----------------------+
 | Network Outputs       |
 +-----------------------*/
output "network_interface_id" {
  description = "The ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "network_security_group_id" {
  description = "The ID of the network security group"
  value       = azurerm_network_security_group.this.id
}

output "vnet_id" {
  description = "The ID of the VNet (created or existing)"
  value       = local.create_network ? azurerm_virtual_network.this[0].id : var.network.vnet_id
}

output "subnet_id" {
  description = "The ID of the subnet (created or existing)"
  value       = local.subnet_id
}

/*-----------------------+
 | SSH Key Outputs       |
 +-----------------------*/
output "ssh_private_key" {
  description = "The generated SSH private key (if generate_ssh_key = true)"
  value       = local.use_generated_key ? tls_private_key.ssh[0].private_key_pem : null
  sensitive   = true
}

output "ssh_public_key" {
  description = "The SSH public key used for the VM"
  value       = local.ssh_public_key
}

/*-----------------------+
 | Identity Outputs      |
 +-----------------------*/
output "storage_backend_identity_id" {
  description = "The resource ID of the storage backend managed identity"
  value       = var.storage_backend_identity_id
}
