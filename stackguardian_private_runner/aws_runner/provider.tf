terraform {
  required_providers {
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = "1.5.2"
    }
    aws = {
      source = "hashicorp/aws"
    }
    external = {
      source = "hashicorp/external"
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
