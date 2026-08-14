terraform {
  required_version = "= 1.5.7"

  required_providers {
    stackguardian = {
      source  = "StackGuardian/stackguardian"
      version = ">= 1.12.0, < 2.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.58.0, < 7.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.1, < 6.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.9.0, < 4.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 7.44.0, < 8.0.0"
    }
  }
}

# StackGuardian provider configuration
provider "stackguardian" {
  api_key  = var.stackguardian_api_key
  org_name = var.stackguardian_org_name
  api_uri  = var.stackguardian_api_uri
}

provider "aws" {
  region = local.aws_provider_region
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

provider "google" {
  # Avoid requiring gcloud ADC when this root has no GCP resources.
  access_token = local.has_gcp_connector ? null : "unused"
}
