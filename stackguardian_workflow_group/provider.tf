terraform {
  required_providers {
    stackguardian = {
      source  = "StackGuardian/stackguardian"
      version = "1.12.0"
    }
  }
}

provider "stackguardian" {
  org_name = var.org_name
  api_key  = var.api_key
  api_uri  = var.sg_api_uri
}