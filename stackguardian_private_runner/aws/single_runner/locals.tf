# Extract SG org name from environment if not provided
data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\"}'"
  ]
}

locals {
  # StackGuardian configuration - use provided values or extract from environment
  sg_org_name = (
    var.stackguardian.org_name != ""
    ? var.stackguardian.org_name
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = var.stackguardian.api_uri

  # Effective prefix for resource naming (optionally includes org name)
  effective_prefix = (
    var.override_names.include_org_in_prefix && local.sg_org_name != ""
    ? "${var.override_names.global_prefix}_${local.sg_org_name}"
    : var.override_names.global_prefix
  )

  # Determine which subnet to use for EC2 instance
  # Priority: private_subnet_id > public_subnet_id
  subnet_id = coalesce(
    var.network.private_subnet_id,
    var.network.public_subnet_id
  )

  # Whether to create NAT Gateway infrastructure
  create_nat_gateway = (
    var.network.create_network_infrastructure &&
    var.network.private_subnet_id != "" &&
    var.network.public_subnet_id != ""
  )

  # SSH key logic: custom public key > named key > no key
  use_custom_key = var.firewall.ssh_public_key != ""
  use_named_key  = var.firewall.ssh_key_name != "" && var.firewall.ssh_public_key == ""
  ssh_key_name   = local.use_custom_key ? aws_key_pair.this[0].key_name : (local.use_named_key ? var.firewall.ssh_key_name : "")

  # Combine module security group with additional security groups
  all_security_group_ids = concat(
    [aws_security_group.this.id],
    var.network.additional_security_group_ids
  )
}
