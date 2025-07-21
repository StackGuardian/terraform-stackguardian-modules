# Security Group for EC2

# data "stackguardian_runner_group_token" "this" {
#   runner_group_id = stackguardian_runner_group.this.resource_name
# }

# Use the custom AMI if built, otherwise use the provided one
# resource "aws_instance" "this" {
#   ami                  = local.runner_ami_id
#   instance_type        = var.instance_type
#   iam_instance_profile = aws_iam_instance_profile.this.name

#   subnet_id                   = var.subnet_id
#   vpc_security_group_ids      = [aws_security_group.this.id]
#   key_name                    = var.ssh_key_name
#   associate_public_ip_address = var.associate_public_ip_address

#   metadata_options {
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 2
#     http_endpoint               = "enabled"
#   }

#   root_block_device {
#     volume_size           = 100
#     volume_type           = "gp3"
#     delete_on_termination = true
#   }

#   tags = {
#     Name = "${var.name_prefix}-private-runner"
#   }

#   user_data = var.build_custom_ami ? null : base64encode("${templatefile("${path.module}/templates/user_data_all.sh", {
#     os_family            = var.os_family
#     sg_org_name          = var.sg_org_name
#     sg_api_uri           = var.sg_api_uri
#     sg_runner_group_name = stackguardian_runner_group.this.resource_name

#     # TODO (adis.halilovic@stackguardian.io):
#     # The token is hardcoded for now using var.sg_runner_token,
#     # since there is an issue with stackguardian provider to fetch runner_token.

#     # sg_runner_group_token = data.stackguardian_runner_group_token.this.runner_group_token
#     sg_runner_group_token = (
#       stackguardian_runner_group.this.runner_token != null
#       ? stackguardian_runner_group.this.runner_token
#       : var.sg_runner_token
#     )
#   })}")
# }
