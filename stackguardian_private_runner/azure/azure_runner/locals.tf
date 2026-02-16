# Extract SG org name and API URI from environment if not provided
data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\", \"sg_api_uri\": \"'$${SG_API_URI:-https://api.app.stackguardian.io}'\"}'"
  ]
}

locals {
  # StackGuardian configuration - use provided values or extract from environment
  sg_org_name = (
    var.stackguardian.org_name != ""
    ? var.stackguardian.org_name
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = (
    var.stackguardian.api_uri != ""
    ? var.stackguardian.api_uri
    : data.external.env.result.sg_api_uri
  )

  # Network mode logic
  create_network       = var.network.create_network
  use_existing_network = !local.create_network

  # Subnet ID (created or existing)
  subnet_id = (
    local.create_network
    ? azurerm_subnet.this[0].id
    : var.network.subnet_id
  )

  # SSH key logic: provided key > generated key
  use_generated_key = var.firewall.generate_ssh_key && var.firewall.ssh_public_key == ""
  ssh_public_key = (
    local.use_generated_key
    ? tls_private_key.ssh[0].public_key_openssh
    : var.firewall.ssh_public_key
  )

  # Sanitized prefix for Azure naming
  sanitized_prefix = replace(lower(var.override_names.global_prefix), "_", "-")

  # VM name
  vm_name = "${local.sanitized_prefix}-private-runner"

  # Combine NSG IDs
  all_nsg_ids = concat(
    [azurerm_network_security_group.this.id],
    var.network.additional_nsg_ids
  )
}
