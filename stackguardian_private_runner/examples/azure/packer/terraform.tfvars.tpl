# ============================================================
# StackGuardian Private Runner - Azure Image Build
# ============================================================
# Copy this file to terraform.tfvars and fill in your values.
# Everything commented out is optional and shown with its default.
# ============================================================

# --- Required: Where the image lives ---
# Created by this example, and removed again on destroy.
resource_group_name = "sg-runner-images"

# --- Optional: Where and on what to build ---
# A managed image is regional - build it where you intend to create runners.
# azure_location = "westeurope"
# vm_size        = "Standard_D2s_v3"   # exists only for the length of the build
#
# Set false to build into a resource group that already exists. This example
# then leaves it alone on destroy.
# create_resource_group = true

# --- Optional: Build networking ---
# By default Packer creates and destroys its own throwaway VNet for the build.
# Point it at an existing VNet when the build must run inside your network -
# Packer then uses the private IP only, so wherever you run OpenTofu needs a
# route into that subnet.
# network = {
#   vnet_name           = "my-vnet"
#   subnet_name         = "build-subnet"
#   resource_group_name = "my-network-rg"
#   proxy_url           = ""
# }

# --- Optional: Image contents ---
# Every value here is baked in at build time, so changing one has no effect on
# an existing image until you trigger a rebuild (see rebuild_image_token below).
#
# publisher must be "Canonical" or "RedHat".
# os = {
#   publisher                = "Canonical"
#   offer                    = "0001-com-ubuntu-server-jammy"
#   sku                      = "22_04-lts-gen2"
#   version                  = "latest"
#   update_os_before_install = true
#   user_script              = ""   # extra shell run after standard setup
# }
#
# image_name_prefix = "sg-runner"
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
# Packer builds on the first apply only. Later plans reuse the recorded image.
# To build a new one, change rebuild_image_token to any new value:
# packer_config = {
#   version                   = "1.14.1"
#   rebuild_image_token       = "2026-08-25"
#   cleanup_images_on_destroy = true
# }
