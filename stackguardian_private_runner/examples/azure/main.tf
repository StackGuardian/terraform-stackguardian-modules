/*============================================================+
 | Stage 0: Runner Group                                      |
 | Creates StackGuardian runner group + Azure storage backend |
 +============================================================*/
module "runner_group" {
  source = "../../runner_group"

  cloud_provider              = "azure"
  azure_location              = var.azure_location
  create_azure_resource_group = false
  azure_resource_group_name   = var.runner_storage_resource_group_name
  azure_storage               = var.azure_storage
  max_runners                 = var.max_runners

  stackguardian = var.stackguardian

  override_names = {
    global_prefix         = var.prefix
    include_org_in_prefix = local.include_org_in_prefix
  }
}

/*============================================================+
 | Stage 1: Networking                                        |
 | VNet, Subnet, NSG (inbound SSH + all outbound)             |
 +============================================================*/

resource "azurerm_virtual_network" "this" {
  name                = "${local.sanitized_prefix}-vnet"
  address_space       = var.network.vnet_address_space
  location            = var.azure_location
  resource_group_name = var.compute_resource_group_name

  tags = local.common_tags
}

resource "azurerm_subnet" "this" {
  name                 = "${local.sanitized_prefix}-subnet"
  resource_group_name  = var.compute_resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.network.subnet_address_prefix]
}

resource "azurerm_network_security_group" "this" {
  name                = "${local.sanitized_prefix}-nsg"
  location            = var.azure_location
  resource_group_name = var.compute_resource_group_name

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_address_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

/*============================================================+
 | Stage 2: Single RHEL Runner VM                             |
 | Marketplace RHEL 9.8 image; Docker + sg-runner installed   |
 | at first boot via custom_data, then registers.             |
 +============================================================*/

resource "azurerm_public_ip" "this" {
  name                = "${local.sanitized_prefix}-pip"
  location            = var.azure_location
  resource_group_name = var.compute_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_network_interface" "this" {
  name                = "${local.sanitized_prefix}-nic"
  location            = var.azure_location
  resource_group_name = var.compute_resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = local.vm_name
  resource_group_name = var.compute_resource_group_name
  location            = var.azure_location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids           = [azurerm_network_interface.this.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = var.rhel_image.publisher
    offer     = var.rhel_image.offer
    sku       = var.rhel_image.sku
    version   = var.rhel_image.version
  }

  os_disk {
    caching              = var.vm_os_disk.caching
    storage_account_type = var.vm_os_disk.storage_account_type
    disk_size_gb         = var.vm_os_disk.disk_size_gb
  }

  custom_data = base64encode(
    templatefile("${path.module}/templates/install_runner.sh.tpl",
      {
        sg_org_name           = module.runner_group.sg_org_name
        sg_api_uri            = module.runner_group.sg_api_uri
        sg_runner_group_name  = module.runner_group.runner_group_name
        sg_runner_group_token = module.runner_group.runner_group_token
        docker_version        = var.docker_version
        sg_runner_version     = var.sg_runner_version
        admin_username        = var.admin_username
        startup_timeout       = tostring(var.runner_startup_timeout)
      }
    )
  )

  tags = merge(local.common_tags, {
    Name = local.vm_name
  })
}
