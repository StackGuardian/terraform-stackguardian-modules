# ============================================================
# StackGuardian Private Runner - AWS Quickstart
# ============================================================
# Copy this file to terraform.tfvars and fill in your values.
# Everything commented out is optional and shown with its default.
# ============================================================

# --- Required: StackGuardian credentials ---
stackguardian = {
  api_key  = "sgu_xxxxxxxxxxxxxxxxxxxxx" # Your SG API key
  org_name = "my-org"                    # Your SG organization name
  # api_uri = "https://api.app.stackguardian.io"  # EU1 (default)
  # api_uri = "https://api.us.stackguardian.io"   # US1
}

# --- Required: AWS network ---
aws_region       = "eu-central-1"
vpc_id           = "vpc-0123456789abcdef0"
public_subnet_id = "subnet-0123456789abcdef0"

# Security groups of any VPC *interface endpoints* the runner must reach
# (STS, EC2, SSM, ECR, ...). The module adds an inbound HTTPS (443) rule to each
# one, allowing traffic from the runner's security group.
#
# Leave empty for a VPC with a normal internet path. If your VPC resolves AWS
# APIs through interface endpoints and you leave this empty, the runner will
# hang on plan with no obvious error - the endpoint silently drops its traffic.
vpc_endpoint_security_group_ids = []

# --- Optional: Resource naming ---
# override_names = {
#   global_prefix         = "SG_RUNNER"
#   include_org_in_prefix = false
#   runner_group_name     = ""  # default: "<prefix>-runner-group-<account_id>"
#   connector_name        = ""  # default: "<prefix>-private-runner-backend-<account_id>"
# }

# --- Optional: Runner group ---
# max_runners                   = 3
# force_destroy_storage_backend = false  # true also deletes S3 contents on destroy

# --- Optional: AMI build ---
# packer_instance_type = "t3.medium"
#
# Packer builds the AMI on the first apply only. Later plans reuse it, so the
# runner keeps the same image. To build a new one, change the token below to
# any new value:
# packer_config = {
#   version           = "1.14.1"
#   rebuild_ami_token = "2026-07-30"
#   deregistration_protection = {
#     enabled       = true
#     with_cooldown = false
#   }
#   delete_snapshots        = true
#   cleanup_amis_on_destroy = true
# }
#
# os = {
#   family                   = "amazon"  # amazon | ubuntu | rhel
#   version                  = ""        # required for ubuntu/rhel
#   update_os_before_install = true
#   ssh_username             = ""        # auto-detected per family when empty
#   user_script              = ""        # extra shell run after standard setup
# }
#
# terraform = {
#   primary_version     = "1.9.8"
#   additional_versions = ["1.8.5"]
# }
# opentofu = {
#   primary_version = "1.8.8"
# }
#
# By default the AMI bakes in the latest stable sg-runner release. Set
# pre_release = true to use the newest pre-release instead (falls back to the
# latest stable when there is none). On an existing deployment, also bump
# packer_config.rebuild_ami_token so a new AMI is actually built.
# sg_runner = {
#   pre_release = true
# }

# --- Optional: Runner instance ---
# runner_instance_type = "t3.xlarge"
# volume = {
#   type                  = "gp3"
#   size                  = 100
#   delete_on_termination = false
# }
# Seconds to wait for Docker to come up before the instance shuts itself down.
# Raise it if a custom user_script makes first boot slow.
# runner_startup_timeout = 300

# --- Optional: SSH access ---
# firewall = {
#   ssh_public_key = "ssh-ed25519 AAAA..."
#   ssh_access_rules = {
#     "my-ip" = "203.0.113.10/32"
#   }
#   additional_ingress_rules = {
#     "custom" = {
#       port        = 8080
#       protocol    = "tcp"
#       cidr_blocks = ["10.0.0.0/8"]
#     }
#   }
# }
