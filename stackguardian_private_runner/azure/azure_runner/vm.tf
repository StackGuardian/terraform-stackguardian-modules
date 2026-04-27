/*-------------------------------------------+
 | SSH Key Generation (optional)             |
 +-------------------------------------------*/
resource "tls_private_key" "ssh" {
  count = local.use_generated_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

/*-------------------------------------------+
 | Azure Linux Virtual Machine               |
 +-------------------------------------------*/
resource "azurerm_linux_virtual_machine" "this" {
  name                = local.vm_name
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  size                = var.vm_size

  admin_username                  = var.firewall.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.firewall.admin_username
    public_key = local.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  # Use custom image
  source_image_id = var.vm_image_id

  os_disk {
    name                 = "${local.sanitized_prefix}-osdisk"
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
    disk_size_gb         = var.os_disk.disk_size_gb
  }

  # User-Assigned Managed Identity for storage backend access
  identity {
    type         = "UserAssigned"
    identity_ids = [var.storage_backend_identity_id]
  }

  # Custom data for runner registration
  custom_data = base64encode(
    templatefile("${path.module}/templates/register_runner.sh.tpl",
      {
        sg_org_name               = local.sg_org_name
        sg_api_uri                = local.sg_api_uri
        sg_runner_group_name      = var.runner_group_name
        sg_runner_group_token     = var.runner_group_token
        sg_runner_startup_timeout = tostring(var.runner_startup_timeout)
        proxy_url                 = var.network.proxy_url
      }
    )
  )

  tags = merge(local.common_tags, {
    Name = local.vm_name
  })

  lifecycle {
    create_before_destroy = true
  }
}
