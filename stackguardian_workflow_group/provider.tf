terraform {
  required_providers {
    stackguardian = {
      source = "StackGuardian/stackguardian"
      version = "1.0.0-rc5"
    }
  }
}


provider "stackguardian" {
  api_key = var.api_key
  org_name = var.org_name
  api_uri = "https://api.app.stackguardian.io/api/v1/"
}