/*----------------------------------+
 | Packer Azure Image Builder       |
 +----------------------------------*/
output "image_id" {
  description = "The resource ID of the Azure managed image built by this module and recorded in state"
  value       = local.image_id

  precondition {
    condition     = local.image_id != ""
    error_message = "No image recorded: the Packer build produced no image ID. Check packer_manifest.log in the packer module directory."
  }
}

output "image_info" {
  description = "Comprehensive image information for tracking and cleanup"
  value = {
    image_id            = local.image_id
    location            = var.azure_location
    resource_group_name = local.resource_group_name
    os_family           = local.os_family
    os_sku              = var.os.sku
    image_name          = local.image_name
    image_name_prefix   = var.image_name_prefix
    cleanup_settings = {
      automatic_cleanup = var.packer_config.cleanup_images_on_destroy
    }
  }
}

output "resource_group_name" {
  description = "The resource group name where the image is stored"
  value       = local.resource_group_name
}

output "cleanup_commands" {
  description = "Azure CLI commands for manual image cleanup"
  value = {
    list_image   = "az image show --ids ${local.image_id}"
    delete_image = "az image delete --ids ${local.image_id}"
    list_all     = "az image list --resource-group ${local.resource_group_name} --query \"[?starts_with(name, '${var.image_name_prefix}')].{name:name, id:id}\" -o table"
  }
}
