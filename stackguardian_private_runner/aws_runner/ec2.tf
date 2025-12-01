# Create SSH key pair when custom public key is provided
resource "aws_key_pair" "this" {
  count      = local.use_custom_key ? 1 : 0
  key_name   = "${var.override_names.global_prefix}-private-runner-custom-key"
  public_key = var.firewall.ssh_public_key

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner-custom-key"
  }
}

# Single EC2 Instance for StackGuardian Private Runner
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = local.ssh_key_name != "" ? local.ssh_key_name : null

  subnet_id              = var.network.subnet_id
  vpc_security_group_ids = local.all_security_group_ids

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

  user_data_base64 = base64encode(
    templatefile("${path.module}/templates/register_runner.sh.tpl",
      {
        sg_org_name               = local.sg_org_name
        sg_api_uri                = local.sg_api_uri
        sg_runner_group_name      = var.runner_group_name
        sg_runner_group_token     = data.stackguardian_runner_group_token.this.runner_group_token
        sg_runner_startup_timeout = tostring(var.runner_startup_timeout)
      }
    )
  )

  tags = {
    Name = "${var.override_names.global_prefix}-private-runner"
  }

  lifecycle {
    create_before_destroy = true
  }
}
