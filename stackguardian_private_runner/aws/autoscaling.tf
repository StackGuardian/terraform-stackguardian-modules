locals {
  subnet_id = var.private_subnet_id != null ? var.private_subnet_id : var.public_subnet_id

  # SSH key logic: custom public key > named key > no key
  use_custom_key = var.ssh_public_key != ""
  use_named_key  = var.ssh_key_name != "" && var.ssh_public_key == ""
  ssh_key_name   = local.use_custom_key ? aws_key_pair.this[0].key_name : (local.use_named_key ? var.ssh_key_name : "")
}

data "stackguardian_runner_group_token" "this" {
  runner_group_id = stackguardian_runner_group.this.resource_name
}

# Create SSH key pair when custom public key is provided
resource "aws_key_pair" "this" {
  count      = local.use_custom_key ? 1 : 0
  key_name   = "${var.name_prefix}-private-runner-custom-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.name_prefix}-private-runner-custom-key"
  }
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-private-runner-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = local.ssh_key_name != "" ? local.ssh_key_name : null

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
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
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = var.delete_volume_on_termination
    }
  }

  user_data = base64encode("${templatefile("${path.module}/templates/register_runner.sh", {
    sg_org_name = local.sg_org_name
    # sg_api_uri            = var.sg_api_uri
    sg_runner_group_name  = stackguardian_runner_group.this.resource_name
    sg_runner_group_token = data.stackguardian_runner_group_token.this.runner_group_token
  })}")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-private-runner-asg"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                      = "${var.name_prefix}-private-runner-asg"
  vpc_zone_identifier       = [local.subnet_id]
  target_group_arns         = []
  health_check_type         = "EC2"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-private-runner-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [desired_capacity]
  }
}
