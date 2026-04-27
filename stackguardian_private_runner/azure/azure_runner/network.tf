/*-------------------------------------------+
 | Virtual Network (optional - when creating)|
 +-------------------------------------------*/
resource "azurerm_virtual_network" "this" {
  count = local.create_network ? 1 : 0

  name                = "${local.sanitized_prefix}-vnet"
  address_space       = var.network.vnet_address_space
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-vnet"
  })
}

resource "azurerm_subnet" "this" {
  count = local.create_network ? 1 : 0

  name                 = "${local.sanitized_prefix}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.network.subnet_address_prefix]
}

/*-------------------------------------------+
 | Network Security Group                    |
 +-------------------------------------------*/
resource "azurerm_network_security_group" "this" {
  name                = "${local.sanitized_prefix}-nsg"
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  # Allow SSH (only if SSH access rules are provided)
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

  # Additional inbound rules
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

  # Allow all outbound traffic
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
    Name = "${local.sanitized_prefix}-nsg"
  })
}

/*-------------------------------------------+
 | NAT Gateway (optional)                    |
 +-------------------------------------------*/
# Provides outbound internet access for runners on a private (created) subnet.
# Only created when network.create_network_infrastructure = true AND
# the module is creating the subnet itself.
resource "azurerm_public_ip" "nat" {
  count = local.create_nat_gateway ? 1 : 0

  name                = "${local.sanitized_prefix}-nat-pip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-nat-pip"
  })
}

resource "azurerm_nat_gateway" "this" {
  count = local.create_nat_gateway ? 1 : 0

  name                    = "${local.sanitized_prefix}-natgw"
  location                = var.azure_location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-natgw"
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

/*-------------------------------------------+
 | Public IP (optional)                      |
 +-------------------------------------------*/
resource "azurerm_public_ip" "this" {
  count = var.network.associate_public_ip ? 1 : 0

  name                = "${local.sanitized_prefix}-pip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-pip"
  })
}

/*-------------------------------------------+
 | Network Interface                         |
 +-------------------------------------------*/
resource "azurerm_network_interface" "this" {
  name                = "${local.sanitized_prefix}-nic"
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.network.associate_public_ip ? azurerm_public_ip.this[0].id : null
  }

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-nic"
  })
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}
