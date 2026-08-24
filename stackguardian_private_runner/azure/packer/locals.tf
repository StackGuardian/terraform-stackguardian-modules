locals {
  # Determine OS family from publisher
  os_family = var.os.publisher == "Canonical" ? "ubuntu" : "rhel"

  # SSH username based on OS
  ssh_usernames = {
    ubuntu = "ubuntu"
    rhel   = "azureuser"
  }
  ssh_username = local.ssh_usernames[local.os_family]

  # Image name with timestamp placeholder (actual timestamp added by Packer)
  image_name = "${var.image_name_prefix}-${local.os_family}-${var.os.sku}"

  # Resource group name (created or existing)
  resource_group_name = var.create_resource_group ? azurerm_resource_group.packer[0].name : var.resource_group_name

  # Network configuration (empty strings mean Packer creates temporary networking)
  use_existing_network = var.network.vnet_name != "" && var.network.subnet_name != ""

  # The image built by this module, as recorded in state. Packer runs on the first
  # apply and then only when packer_config.rebuild_image_token changes, so this
  # value stays stable across re-plans.
  image_id = terraform_data.image_id.output
}
