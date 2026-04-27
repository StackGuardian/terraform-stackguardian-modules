/*-------------------------------------------+
 | SSH Key Generation (optional)             |
 +-------------------------------------------*/
resource "tls_private_key" "ssh" {
  count = local.use_generated_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

/*-------------------------------------------+
 | Linux Virtual Machine Scale Set           |
 +-------------------------------------------*/
# Manual upgrade policy mirrors aws_launch_template + ASG pattern: changes
# to the SKU/image require explicit instance refresh, which the autoscaler
# (or operator) drives — the VMSS resource itself does not roll instances.
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = local.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  sku                 = var.vm_size
  instances           = var.scaling.desired_capacity

  admin_username                  = var.firewall.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.firewall.admin_username
    public_key = local.ssh_public_key
  }

  source_image_id = var.vm_image_id

  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
    disk_size_gb         = var.os_disk.disk_size_gb
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.storage_backend_identity_id]
  }

  network_interface {
    name                      = "${local.sanitized_prefix}-vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.this.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = local.subnet_id
    }
  }

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

  upgrade_mode = "Manual"

  tags = merge(local.common_tags, {
    Name = local.vmss_name
  })

  lifecycle {
    # Autoscaler drives instance count after first apply.
    ignore_changes = [instances]
  }
}
