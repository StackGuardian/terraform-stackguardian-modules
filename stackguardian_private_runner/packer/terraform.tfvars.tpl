/*-------------------+
 | General Variables |
 +-------------------*/
aws_region    = "eu-central-1"
instance_type = "t3.medium"


/*----------------------------+
 | AMI Build Network Settings |
 +----------------------------*/
network = {
  vpc_id           = "vpc-"
  public_subnet_id = "subnet-"
}

/*---------------------------+
 | Operating System Settings |
 +---------------------------*/
# RHEL 9.4
# os = {
#   family                   = "rhel"
#   version                  = "9.4"
#   update_os_before_install = true
#   ssh_username             = ""
#   user_script              = ""
# }

# Alternative OS configurations:
# Amazon Linux 2:
os = {
  family                   = "amazon"
  version                  = ""
  update_os_before_install = false
  ssh_username             = ""
  user_script              = ""
}

# Ubuntu:
# os = {
#   family                   = "ubuntu"
#   version                  = "22.04"
#   update_os_before_install = true
#   ssh_username             = ""
#   user_script              = ""
# }

# Example user scripts:
# os = {
#   family                   = "ubuntu"
#   version                  = "22.04"
#   update_os_before_install = true
#   ssh_username             = ""
#   user_script              = "apt update && apt install jq htop"
# }

# os = {
#   family                   = "amazon"
#   version                  = ""
#   update_os_before_install = true
#   ssh_username             = ""
#   user_script = <<EOT
#     # Install K3s
#     PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
#     curl -sfL https://get.k3s.io \
#       | INSTALL_K3S_EXEC="server --tls-san $PUBLIC_IP --node-external-ip $PUBLIC_IP --bind-address 0.0.0.0" sh -
#   EOT
# }

/*---------------------------------+
 | Terraform Installation Settings |
 +---------------------------------*/
# terraform = {
#   primary_version     = "1.12.2"
#   additional_versions = ["1.13.0", "1.10.1"]
# }

/*-------------------------------+
 | OpenTofu Installation Settings |
 +-------------------------------*/
# opentofu = {
#   primary_version     = "1.10.5"
#   additional_versions = ["1.10.1", "1.9.1"]
# }

# ## To disable Terraform/OpenTofu installation, use empty strings:
# terraform = {
#   primary_version     = ""
#   additional_versions = []
# }

# opentofu = {
#   primary_version     = ""
#   additional_versions = []
# }

/*----------------------------------+
 | Packer Configuration Variables   |
 +----------------------------------*/
# packer_config = {
#   version = "1.14.1"
#   deregistration_protection = {
#     enabled = true         # Enable/disable deregistration protection
#     with_cooldown = false  # Enable/disable cooldown period
#   }
#   delete_snapshots = true  # Delete EBS snapshots during AMI cleanup
#   cleanup_amis_on_destroy = true  # Automatically deregister AMIs on terraform destroy
# }
