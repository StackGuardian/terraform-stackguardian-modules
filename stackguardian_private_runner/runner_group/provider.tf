terraform {
  required_providers {
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = ">= 1.3.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
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

provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = var.cloud_provider != "aws"
  skip_requesting_account_id  = var.cloud_provider != "aws"
}

provider "azurerm" {
  features {}
}

provider "stackguardian" {
  api_key  = var.stackguardian.api_key
  org_name = local.sg_org_name
  api_uri  = local.sg_api_uri
}
