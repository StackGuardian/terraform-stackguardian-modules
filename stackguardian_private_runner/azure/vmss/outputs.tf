/*-----------------------+
 | VMSS Outputs          |
 +-----------------------*/
output "vmss_id" {
  description = "The ID of the Linux VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.this.id
}

output "vmss_name" {
  description = "The name of the Linux VM Scale Set (consume from azure/autoscaler vmss.name input)"
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "vmss_resource_group_name" {
  description = "The resource group name containing the VMSS (consume from azure/autoscaler vmss.resource_group_name input)"
  value       = var.resource_group_name
}

/*-----------------------+
 | Network Outputs       |
 +-----------------------*/
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
  description = "The generated SSH private key (only populated when firewall.generate_ssh_key = true)"
  value       = local.use_generated_key ? tls_private_key.ssh[0].private_key_pem : null
  sensitive   = true
}

output "ssh_public_key" {
  description = "The SSH public key used for the VMSS instances"
  value       = local.ssh_public_key
}

/*-----------------------+
 | Identity Outputs      |
 +-----------------------*/
output "storage_backend_identity_id" {
  description = "The resource ID of the storage backend managed identity (passed through)"
  value       = var.storage_backend_identity_id
}
