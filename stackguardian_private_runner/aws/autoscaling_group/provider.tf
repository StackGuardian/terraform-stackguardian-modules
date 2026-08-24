terraform {
  # optional() attributes with defaults (var.network, var.scaling, var.firewall)
  # need 1.3+
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
