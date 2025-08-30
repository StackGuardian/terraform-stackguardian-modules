locals {
  subnet_id = var.network.private_subnet_id != "" ? var.network.private_subnet_id : var.network.public_subnet_id

  # SSH key logic: custom public key > named key > no key
  use_custom_key = var.firewall.ssh_public_key != ""
  use_named_key  = var.firewall.ssh_key_name != "" && var.firewall.ssh_public_key == ""
  ssh_key_name   = local.use_custom_key ? aws_key_pair.this[0].key_name : (local.use_named_key ? var.firewall.ssh_key_name : "")
}

data "stackguardian_runner_group_token" "this" {
  runner_group_id = stackguardian_runner_group.this.resource_name
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

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "this" {
  name_prefix   = "${var.override_names.global_prefix}-private-runner-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = local.ssh_key_name != "" ? local.ssh_key_name : null

  network_interfaces {
    associate_public_ip_address = var.network.associate_public_ip
    security_groups             = [aws_security_group.this.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.volume.size
      volume_type           = var.volume.type
      delete_on_termination = var.volume.delete_on_termination
    }
  }

  user_data = base64encode(
    "${templatefile("${path.module}/templates/register_runner.sh.tpl",
      {
        sg_org_name               = local.sg_org_name
        sg_api_uri                = local.sg_api_uri
        sg_runner_group_name      = stackguardian_runner_group.this.resource_name
        sg_runner_group_token     = data.stackguardian_runner_group_token.this.runner_group_token
        sg_runner_startup_timeout = tostring(var.scaling.scale_out_cooldown_duration)
      }
    )}"
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.override_names.global_prefix}-private-runner-asg"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                      = "${var.override_names.global_prefix}-private-runner-asg"
  vpc_zone_identifier       = [local.subnet_id]
  target_group_arns         = []
  health_check_type         = "EC2"
  health_check_grace_period = 300

  min_size         = var.scaling.scale_in_threshold
  max_size         = var.scaling.scale_out_threshold
  desired_capacity = var.scaling.min_runners

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.override_names.global_prefix}-private-runner-asg"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage       = 50
      instance_warmup              = 300
      scale_in_protected_instances = "Refresh"
      standby_instances            = "Terminate"
    }
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [desired_capacity]
  }
}
