terraform {
  required_version = ">= 1.0"

  required_providers {
    # Pinned to 4.x: the runner_group module is written against azurerm 4.x but
    # only constrains ">= 3.0", so the ceiling has to live in the root module.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}
