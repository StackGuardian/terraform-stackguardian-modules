terraform {
  # terraform_data (used by the packer module to record the built image ID) needs 1.4+
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    null = {
      source = "hashicorp/null"
    }
    external = {
      source = "hashicorp/external"
    }
  }
}

# No provider block here: azure/packer declares and configures its own.

# -------------------------------------------------------
# Packer Managed Image Builder
#   Builds the runner image: Docker, jq, cron, sg-runner and
#   optionally Terraform/OpenTofu.
#
#   By default Packer creates and destroys its own temporary
#   networking for the build VM. Set var.network to build
#   inside a VNet you already have.
# -------------------------------------------------------
module "packer" {
  source = "../../../azure/packer"

  azure_location = var.azure_location
  vm_size        = var.vm_size

  resource_group_name   = var.resource_group_name
  create_resource_group = var.create_resource_group

  network = var.network

  os                = var.os
  packer_config     = var.packer_config
  image_name_prefix = var.image_name_prefix
  terraform         = var.terraform
  opentofu          = var.opentofu
  sg_runner         = var.sg_runner
}
