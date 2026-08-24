terraform {
  # optional() attributes with defaults (var.storage_backend) need 1.3+
  required_version = ">= 1.3.0"

  required_providers {
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = ">= 1.3.3"
    }
  }
}
