terraform {
  # terraform_data (used by the packer module to record the built image ID) needs 1.4+
  required_version = ">= 1.4.0"

  required_providers {
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = ">= 1.3.3"
    }
    # Pinned to 4.x: the azure/* modules use azurerm_subnet.service_endpoints,
    # which azurerm 5.x removed. Their own constraint is only ">= 3.0", so the
    # root module is where the ceiling has to live.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0"
    }
    external = {
      source = "hashicorp/external"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source = "hashicorp/null"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

# The root module owns the managed identity below, so it needs its own azurerm
# configuration; the child modules declare their own.
provider "azurerm" {
  features {}
}

# -------------------------------------------------------
# Module 1: StackGuardian Runner Group
#   Creates: runner group, resource group, storage account,
#            blob container, AAD app + OIDC connector
# -------------------------------------------------------
module "runner_group" {
  source = "../../../azure/runner_group"

  azure_location = var.azure_location

  stackguardian = var.stackguardian

  override_names = var.override_names

  # Create the resource group here and reuse it for the image and the VM, so the
  # whole deployment lands in one place and one destroy removes it.
  create_azure_resource_group = true
  azure_resource_group_name   = var.azure_resource_group_name

  create_storage_backend             = true
  azure_storage                      = var.azure_storage
  create_blob_reader_role_assignment = var.create_role_assignments

  max_runners = var.max_runners
}

# -------------------------------------------------------
# Module 2: Packer Managed Image Builder
#   Builds the image with sg-runner, Docker, Terraform, etc.
# -------------------------------------------------------
module "packer" {
  source = "../../../azure/packer"

  azure_location = var.azure_location
  vm_size        = var.packer_vm_size

  # Reuse the runner group's resource group rather than creating a second one
  resource_group_name   = module.runner_group.azure_resource_group_name
  create_resource_group = false

  # Empty vnet/subnet: Packer creates and tears down its own temporary networking
  network = var.packer_network

  os                = var.os
  packer_config     = var.packer_config
  image_name_prefix = var.image_name_prefix
  terraform         = var.terraform
  opentofu          = var.opentofu
}

# -------------------------------------------------------
# Storage Backend Managed Identity
#   The runner VM authenticates to the storage account with
#   this User-Assigned Managed Identity. The runner group
#   module does not create one, so the root module does.
# -------------------------------------------------------
resource "azurerm_user_assigned_identity" "storage_backend" {
  name                = "${local.sanitized_prefix}-storage-backend-identity"
  resource_group_name = module.runner_group.azure_resource_group_name
  location            = var.azure_location

  tags = local.common_tags
}

# Read/write on the blob container, because the runner both reads and writes the
# state it produces for the jobs it runs.
resource "azurerm_role_assignment" "storage_backend" {
  count = var.create_role_assignments ? 1 : 0

  scope                = module.runner_group.azure_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.storage_backend.principal_id
}

# -------------------------------------------------------
# Module 3: Single Runner VM
#   Deploys the private runner from the image built above,
#   using the runner group config from Module 1
# -------------------------------------------------------
module "azure_runner" {
  source = "../../../azure/azure_runner"

  vm_image_id = module.packer.image_id
  vm_size     = var.runner_vm_size

  azure_location      = var.azure_location
  resource_group_name = module.runner_group.azure_resource_group_name

  runner_group_name           = module.runner_group.runner_group_name
  runner_group_token          = module.runner_group.runner_group_token
  storage_backend_identity_id = azurerm_user_assigned_identity.storage_backend.id

  stackguardian = var.stackguardian

  override_names = {
    global_prefix         = var.override_names.global_prefix
    include_org_in_prefix = var.override_names.include_org_in_prefix
  }

  network = {
    create_network        = true
    vnet_address_space    = var.network.vnet_address_space
    subnet_address_prefix = var.network.subnet_address_prefix
    service_endpoints     = var.network.service_endpoints
    associate_public_ip   = true
  }

  os_disk                = var.os_disk
  firewall               = var.firewall
  runner_startup_timeout = var.runner_startup_timeout

  # No depends_on on the role assignment: azure_runner declares its own provider
  # configurations, which makes it a legacy module that cannot take depends_on.
  # The VM does not touch the storage backend at boot, and Azure RBAC takes a
  # minute to propagate regardless, so the ordering is not load-bearing.
}
