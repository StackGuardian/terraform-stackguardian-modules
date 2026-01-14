# Create SSH key pair when custom public key is provided (only when create_asg = true)
resource "aws_key_pair" "this" {
  count = var.create_asg && local.use_custom_key ? 1 : 0

  key_name   = "${local.effective_prefix}-private-runner-custom-key"
  public_key = var.firewall.ssh_public_key

  tags = {
    Name = "${local.effective_prefix}-private-runner-custom-key"
  }
}

# Launch Template for Auto Scaling Group (only created when create_asg = true)
resource "aws_launch_template" "this" {
  count = var.create_asg ? 1 : 0

  name_prefix   = "${local.effective_prefix}-private-runner-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = local.ssh_key_name != "" ? local.ssh_key_name : null

  network_interfaces {
    associate_public_ip_address = var.network.associate_public_ip
    security_groups             = local.all_security_group_ids
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this[0].name
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  # Root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Data volume
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.volume.size
      volume_type           = var.volume.type
      delete_on_termination = var.volume.delete_on_termination
    }
  }

  user_data = base64encode(
    templatefile("${path.module}/templates/register_runner.sh.tpl",
      {
        sg_org_name               = local.sg_org_name
        sg_api_uri                = local.sg_api_uri
        sg_runner_group_name      = var.runner_group_name
        sg_runner_group_token     = var.runner_group_token
        sg_runner_startup_timeout = tostring(var.runner_startup_timeout)
      }
    )
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.effective_prefix}-private-runner-asg"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group (only created when create_asg = true)
resource "aws_autoscaling_group" "this" {
  count = var.create_asg ? 1 : 0

  name                      = "${local.effective_prefix}-private-runner-asg"
  vpc_zone_identifier       = [local.subnet_id]
  target_group_arns         = []
  health_check_type         = "EC2"
  health_check_grace_period = 300

  min_size         = var.scaling.min_size
  max_size         = var.scaling.max_size
  desired_capacity = var.scaling.desired_capacity

  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.effective_prefix}-private-runner-asg"
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
    ignore_changes        = [desired_capacity]
  }
}
