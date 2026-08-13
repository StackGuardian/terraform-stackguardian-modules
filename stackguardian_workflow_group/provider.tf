terraform {
  required_version = "= 1.5.7"

  required_providers {
    stackguardian = {
      source  = "StackGuardian/stackguardian"
      version = ">= 1.12.0, < 2.0.0"
    }
  }
}
