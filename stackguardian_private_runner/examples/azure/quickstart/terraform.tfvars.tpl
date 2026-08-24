# ============================================================
# StackGuardian Private Runner - Azure Quickstart
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

# --- Required in practice: SSH access ---
# Password auth is always disabled, so the VM needs a key. Supply your own
# public key here; the alternative, generate_ssh_key = true, is the default
# only so the example applies out of the box - it puts the private key in state.
firewall = {
  ssh_public_key = "ssh-ed25519 AAAA..."
  # admin_username = "azureuser"
  #
  # Nothing is open inbound unless you add a rule. Port 22 from one address:
  # ssh_access_rules = {
  #   "my-ip" = "203.0.113.10/32"
  # }
  #
  # additional_inbound_rules = {
  #   "custom" = {
  #     priority               = 200
  #     protocol               = "Tcp"
  #     destination_port_range = "8080"
  #     source_address_prefix  = "10.0.0.0/8"
  #   }
  # }
}

# --- Optional: Azure placement ---
# azure_location = "westeurope"
#
# One resource group holds the storage backend, the managed image, and the VM.
# Leave empty to derive the name from the prefix and subscription ID.
# azure_resource_group_name = ""

# --- Optional: Resource naming ---
# override_names = {
#   global_prefix         = "SG_RUNNER"
#   include_org_in_prefix = false
#   runner_group_name     = ""  # default: "<prefix>-runner-group-<subscription_id>"
#   connector_name        = ""  # default: "<prefix>-private-runner-backend-<subscription_id>"
# }

# --- Optional: Runner group and storage backend ---
# max_runners = 3
# azure_storage = {
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#}
#
# Set to false if the identity running OpenTofu cannot write role assignments
# (Contributor without User Access Administrator). You must then grant
# "Storage Blob Data Reader" to the connector service principal and
# "Storage Blob Data Contributor" to the runner identity yourself.
# create_role_assignments = true

# --- Optional: Image build ---
# packer_vm_size    = "Standard_D2s_v3"
# image_name_prefix = "sg-runner"
#
# Packer builds the image on the first apply only. Later plans reuse it, so the
# runner keeps the same image. To build a new one, change the token below to
# any new value:
# packer_config = {
#   version                   = "1.14.1"
#   rebuild_image_token       = "2026-08-24"
#   cleanup_images_on_destroy = true
# }
#
# Base Marketplace image. publisher must be "Canonical" or "RedHat".
# os = {
#   publisher                = "Canonical"
#   offer                    = "0001-com-ubuntu-server-jammy"
#   sku                      = "22_04-lts-gen2"
#   version                  = "latest"
#   update_os_before_install = true
#   user_script              = ""  # extra shell run after standard setup
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
# By default Packer builds on its own throwaway VNet. Point it at an existing
# one when the build must run inside your network:
# packer_network = {
#   vnet_name           = "my-vnet"
#   subnet_name         = "build-subnet"
#   resource_group_name = "my-network-rg"
#   proxy_url           = ""
# }

# --- Optional: Runner VM ---
# runner_vm_size = "Standard_D4s_v3"
# os_disk = {
#   caching              = "ReadWrite"
#   storage_account_type = "Premium_LRS"
#   disk_size_gb         = 100
# }
# Seconds to wait for Docker to come up before the VM shuts itself down.
# Raise it if a custom user_script makes first boot slow.
# runner_startup_timeout = 300

# --- Optional: Network ---
# A new VNet and subnet are created for the runner, with a public IP attached.
#
# service_endpoints routes the listed Azure services over the Azure backbone
# instead of the public internet. Add "Microsoft.Storage" if your storage
# account restricts public network access.
# network = {
#   vnet_address_space    = ["10.0.0.0/16"]
#   subnet_address_prefix = "10.0.1.0/24"
#   service_endpoints     = []
# }
