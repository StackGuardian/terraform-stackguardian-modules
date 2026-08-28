# ============================================================
# StackGuardian Private Runner - AWS AMI Build
# ============================================================
# Copy this file to terraform.tfvars and fill in your values.
# Everything commented out is optional and shown with its default.
# ============================================================

# --- Required: Existing network ---
# The build instance runs here. It needs outbound internet access; this example
# never creates networking.
network = {
  vpc_id    = "vpc-0123456789abcdef0"
  subnet_id = "subnet-0123456789abcdef0"
  #
  # Set true when subnet_id is private. Packer then connects over the private
  # IP, so wherever you run OpenTofu needs a route into that subnet.
  # private_subnet = false
  #
  # proxy_url = "http://proxy.example.com:8080"
}

# --- Optional: Where and on what to build ---
# aws_region    = "eu-central-1"   # an AMI is regional - build where you deploy
# instance_type = "t3.medium"      # exists only for the length of the build

# --- Optional: Image contents ---
# Every value here is baked in at build time, so changing one has no effect on
# an existing AMI until you trigger a rebuild (see rebuild_ami_token below).
#
# os.family must be "amazon", "ubuntu", or "rhel"; version is required for the
# latter two.
# os = {
#   family                   = "amazon"
#   version                  = ""
#   update_os_before_install = true
#   ssh_username             = ""   # defaults per family: ec2-user / ubuntu
#   user_script              = ""   # extra shell run after standard setup
# }
#
# ami_name_prefix = "SG-RUNNER-ami"
#
# terraform = {
#   primary_version     = "1.9.8"
#   additional_versions = ["1.8.5"]
# }
# opentofu = {
#   primary_version = "1.8.8"
# }
#
# Bake the newest sg-runner pre-release instead of the latest stable release.
# sg_runner = {
#   pre_release = false
# }

# --- Optional: Build lifecycle ---
# Packer builds on the first apply only. Later plans reuse the recorded AMI. To
# build a new one, change rebuild_ami_token to any new value:
# packer_config = {
#   version           = "1.14.1"
#   rebuild_ami_token = "2026-08-25"
#   deregistration_protection = {
#     enabled       = true
#     with_cooldown = false
#   }
#   delete_snapshots        = true
#   cleanup_amis_on_destroy = true
# }
