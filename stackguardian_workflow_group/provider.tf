terraform {
  required_providers {
    stackguardian = {
      source = "StackGuardian/stackguardian"
      version = "0.2.0-beta4"
    }
  }
}


provider "stackguardian" {
  api_key = var.api_key
  org_name = var.org_name
  api_uri = "https://api.app.stackguardian.io/api/v1/"
}