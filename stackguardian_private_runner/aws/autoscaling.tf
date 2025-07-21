locals {
  subnet_id        = var.private_subnet_id != null ? var.private_subnet_id : var.public_subnet_id
  user_data_script = var.build_custom_ami ? "register_runner.sh" : "user_data_all.sh"
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-private-runner-"
  image_id      = local.runner_ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.this.id]

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
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode("${templatefile("${path.module}/templates/${local.user_data_script}", {
    os_family            = var.os_family
    sg_org_name          = var.sg_org_name
    sg_api_uri           = var.sg_api_uri
    sg_runner_group_name = stackguardian_runner_group.this.resource_name
    # sg_runner_group_token = stackguardian_runner_group.this.runner_token
    sg_runner_group_token = (
      stackguardian_runner_group.this.runner_token != null
      ? stackguardian_runner_group.this.runner_token
      : var.sg_runner_token
    )
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

  depends_on = [null_resource.build_custom_ami, data.external.packer_ami_id]
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
