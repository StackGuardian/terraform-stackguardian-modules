/*-------------------------------------------+
 | Virtual Network (optional - when creating)|
 +-------------------------------------------*/
resource "azurerm_virtual_network" "this" {
  count = local.create_network ? 1 : 0

  name                = "${local.sanitized_prefix}-vmss-vnet"
  address_space       = var.network.vnet_address_space
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-vmss-vnet"
  })
}

resource "azurerm_subnet" "this" {
  count = local.create_network ? 1 : 0

  name                 = "${local.sanitized_prefix}-vmss-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.network.subnet_address_prefix]

  # Reach Azure PaaS (Storage, Key Vault, ...) over the Azure backbone instead
  # of the public internet. Empty list leaves the subnet untouched.
  service_endpoints = local.subnet_service_endpoints
}

/*-------------------------------------------+
 | Network Security Group                    |
 +-------------------------------------------*/
resource "azurerm_network_security_group" "this" {
  name                = "${local.sanitized_prefix}-vmss-nsg"
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = var.firewall.ssh_access_rules
    content {
      name                       = "SSH-${security_rule.key}"
      priority                   = 100 + index(keys(var.firewall.ssh_access_rules), security_rule.key)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.firewall.additional_inbound_rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
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

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-vmss-nsg"
  })
}

/*-------------------------------------------+
 | NAT Gateway (optional)                    |
 +-------------------------------------------*/
resource "azurerm_public_ip" "nat" {
  count = local.create_nat_gateway ? 1 : 0

  name                = "${local.sanitized_prefix}-vmss-nat-pip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-vmss-nat-pip"
  })
}

resource "azurerm_nat_gateway" "this" {
  count = local.create_nat_gateway ? 1 : 0

  name                    = "${local.sanitized_prefix}-vmss-natgw"
  location                = var.azure_location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-vmss-natgw"
  })
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = local.create_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  count = local.create_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.this[0].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}
