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
  region = var.aws_region
}

provider "stackguardian" {
  api_key  = var.stackguardian.api_key
  org_name = local.sg_org_name
  api_uri  = local.sg_api_uri
}
