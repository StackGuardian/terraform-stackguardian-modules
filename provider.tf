terraform {
  required_version = "= 1.5.7"

  required_providers {
    stackguardian = {
      source  = "StackGuardian/stackguardian"
      version = ">= 1.12.0, < 2.0.0"
    }
  }
}

# StackGuardian provider configuration
provider "stackguardian" {
  api_key  = var.stackguardian_api_key
  org_name = var.stackguardian_org_name
  api_uri  = var.stackguardian_api_uri
}
