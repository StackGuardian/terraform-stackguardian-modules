locals {
  subnet_id = var.network.private_subnet_id != "" ? var.network.private_subnet_id : var.network.public_subnet_id

  # SSH key logic: custom public key > named key > no key
  use_custom_key = var.firewall.ssh_public_key != ""
  use_named_key  = var.firewall.ssh_key_name != "" && var.firewall.ssh_public_key == ""
  ssh_key_name   = local.use_custom_key ? aws_key_pair.this[0].key_name : (local.use_named_key ? var.firewall.ssh_key_name : "")
}

# Create SSH key pair when custom public key is provided
resource "aws_key_pair" "this" {
  count      = local.use_custom_key ? 1 : 0
  key_name   = "${var.override_names.global_prefix}-private-runner-custom-key"
  public_key = var.firewall.ssh_public_key

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner-custom-key"
  }
}

# Fetch Runner Group token
data "stackguardian_runner_group_token" "this" {
  runner_group_id = var.stackguardian.runner_group_name
}

# Single EC2 Instance for StackGuardian Private Runner
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = local.ssh_key_name != "" ? local.ssh_key_name : null

  subnet_id = local.subnet_id
  vpc_security_group_ids = [
    aws_security_group.this.id,
    var.network.security_group_id
  ]

  associate_public_ip_address = var.network.associate_public_ip
  iam_instance_profile        = aws_iam_instance_profile.this.name

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  root_block_device {
    volume_size           = var.volume.size
    volume_type           = var.volume.type
    delete_on_termination = var.volume.delete_on_termination
  }

  user_data = base64encode(
    "${templatefile("${path.module}/templates/register_runner.sh.tpl",
      {
        sg_org_name           = local.sg_org_name
        sg_api_uri            = local.sg_api_uri
        sg_runner_group_name  = var.stackguardian.runner_group_name
        sg_runner_group_token = data.stackguardian_runner_group_token.this.runner_group_token
        # sg_runner_group_token = stackguardian_runner_group.storage_backend_config.s3_bucket_name
        # sg_runner_group_token     = var.stackguardian.runner_group_token
        sg_runner_startup_timeout = tostring(var.runner_startup_timeout)
      }
    )}"
  )

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner"
  }

  lifecycle {
    create_before_destroy = true
  }
}
