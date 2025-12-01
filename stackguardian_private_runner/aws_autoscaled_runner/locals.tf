locals {
  # SSH key logic: custom public key > named key > no key
  use_custom_key = var.firewall.ssh_public_key != ""
  use_named_key  = var.firewall.ssh_key_name != "" && var.firewall.ssh_public_key == ""
  ssh_key_name   = local.use_custom_key ? aws_key_pair.this[0].key_name : (local.use_named_key ? var.firewall.ssh_key_name : "")

  # Combine module security group with additional security groups
  all_security_group_ids = var.create_asg ? concat(
    [aws_security_group.this[0].id],
    var.network.additional_security_group_ids
  ) : []

  # ASG name - either created or existing
  asg_name = var.create_asg ? aws_autoscaling_group.this[0].name : var.existing_asg_name

  # Lambda build directory
  lambda_build_dir = "${path.module}/.lambda_build"
}
