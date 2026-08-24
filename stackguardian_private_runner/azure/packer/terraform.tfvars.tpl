/*-------------------+
 | General Variables |
 +-------------------*/
azure_location = "westeurope"
vm_size        = "Standard_D2s_v3"

# Resource group that holds the built managed image.
resource_group_name = "sg-runner-images-rg"

# Set to true to have this module create the resource group above.
# Leave false to reuse a resource group that already exists.
create_resource_group = false

# Prefix for the generated image name. The final name is
# <prefix>-<os_family>-<sku>-<timestamp>, e.g. sg-runner-ubuntu-22_04-lts-gen2-1712345678
image_name_prefix = "sg-runner"

/*------------------------------+
 | Image Build Network Settings |
 +------------------------------*/
# Default: leave everything empty and Packer creates a temporary VNet/subnet,
# public IP and NSG for the build VM, then tears them down afterwards.
network = {}

# Build inside an existing VNet/subnet instead (e.g. to reach a private mirror
# or to satisfy a policy that forbids ad-hoc networking):
# network = {
#   vnet_name           = "sg-runner-vnet"
#   subnet_name         = "build-subnet"
#   resource_group_name = "networking-rg"                  # RG of the VNet, if different
#   proxy_url           = "http://proxy.company.com:8080"  # Optional
# }

/*---------------------------+
 | Operating System Settings |
 +---------------------------*/
# Ubuntu 22.04 LTS (default). publisher must be "Canonical" or "RedHat".
os = {
  publisher                = "Canonical"
  offer                    = "0001-com-ubuntu-server-jammy"
  sku                      = "22_04-lts-gen2"
  version                  = "latest"
  update_os_before_install = true
  user_script              = ""
}

# Ubuntu 24.04 LTS:
# os = {
#   publisher                = "Canonical"
#   offer                    = "ubuntu-24_04-lts"
#   sku                      = "server-gen1"
#   version                  = "latest"
#   update_os_before_install = true
# }

# RHEL 9:
# os = {
#   publisher                = "RedHat"
#   offer                    = "RHEL"
#   sku                      = "9_4"
#   version                  = "latest"
#   update_os_before_install = true
# }

# The SSH user is derived from the publisher (ubuntu for Canonical,
# azureuser for RedHat) - there is no ssh_username input here.

# Example user scripts - run after the base provisioning, on the build VM:
# os = {
#   publisher                = "Canonical"
#   offer                    = "0001-com-ubuntu-server-jammy"
#   sku                      = "22_04-lts-gen2"
#   version                  = "latest"
#   update_os_before_install = true
#   user_script              = "apt-get update && apt-get install -y jq htop"
# }

# os = {
#   publisher = "Canonical"
#   offer     = "0001-com-ubuntu-server-jammy"
#   sku       = "22_04-lts-gen2"
#   version   = "latest"
#   user_script = <<EOT
#     # Install K3s
#     PRIVATE_IP=$(hostname -I | awk '{print $1}')
#     curl -sfL https://get.k3s.io \
#       | INSTALL_K3S_EXEC="server --tls-san $PRIVATE_IP --node-external-ip $PRIVATE_IP --bind-address 0.0.0.0" sh -
#   EOT
# }

/*---------------------------------+
 | Terraform Installation Settings |
 +---------------------------------*/
# terraform = {
#   primary_version     = "1.12.2"
#   additional_versions = ["1.13.0", "1.10.1"]
# }

/*--------------------------------+
 | OpenTofu Installation Settings |
 +--------------------------------*/
# opentofu = {
#   primary_version     = "1.10.5"
#   additional_versions = ["1.10.1", "1.9.1"]
# }

# ## Both default to empty, which skips the install. To be explicit:
# terraform = {
#   primary_version     = ""
#   additional_versions = []
# }

# opentofu = {
#   primary_version     = ""
#   additional_versions = []
# }

/*--------------------------------+
 | Packer Configuration Variables |
 +--------------------------------*/
# The image is built on the first apply, its ID is recorded in state, and every
# following plan reuses it - no rebuild, no cost.
# To build a new one, change rebuild_image_token to any new value (a date, a tool
# version, anything). That forces exactly one rebuild; leaving the new value in
# place never rebuilds again. When cleanup_images_on_destroy is true, the
# superseded image is deleted as part of the same apply.
# packer_config = {
#   version                   = "1.14.1"
#   rebuild_image_token       = ""    # e.g. "2026-07-30" or "tofu-1.11" to force a rebuild
#   cleanup_images_on_destroy = true  # Delete the image this module built on destroy
# }
