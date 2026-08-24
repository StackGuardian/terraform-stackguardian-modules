terraform {
  # optional() attributes with defaults (var.override_names, var.azure_storage) need 1.3+
  required_version = ">= 1.3.0"

  required_providers {
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = ">= 1.3.3"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      # Floor is load-bearing: azurerm_storage_container.storage_account_id landed in 4.x.
      # Ceiling matches the rest of the azure/* modules, which 5.x breaks.
      version = ">= 4.0, < 5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "stackguardian" {
  api_key  = var.stackguardian.api_key
  org_name = local.sg_org_name
  api_uri  = local.sg_api_uri
}
