terraform {
  required_providers {
    stackguardian = {
      source  = "StackGuardian/stackguardian"
      version = "1.3.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

# StackGuardian provider configuration
provider "stackguardian" {
  api_key  = var.api_key
  org_name = var.org_name
  api_uri  = "https://api.app.stackguardian.io"
}

# AWS provider configuration
/*
provider "aws" {
  region = var.region
}
*/