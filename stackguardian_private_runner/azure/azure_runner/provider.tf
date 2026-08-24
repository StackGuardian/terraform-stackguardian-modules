terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Ceiling is load-bearing: azurerm 5.x removed azurerm_subnet.service_endpoints,
      # which this module uses for network.service_endpoints
      version = ">= 3.0, < 5.0"
    }
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = ">= 1.3.3"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
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
