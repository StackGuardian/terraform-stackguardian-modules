terraform {
  required_providers {
    stackguardian = {
      source  = "StackGuardian/stackguardian"
      version = "1.3.3"
    }
    aws = {
      source = "hashicorp/aws"
    }
    null = {
      source = "hashicorp/null"
    }
    external = {
      source = "hashicorp/external"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "stackguardian" {
  api_key  = var.sg_api_key
  org_name = var.sg_org_name
  api_uri  = var.sg_api_uri
}
