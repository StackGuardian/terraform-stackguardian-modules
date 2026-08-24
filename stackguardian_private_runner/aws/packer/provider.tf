terraform {
  # terraform_data (used to record the built AMI ID in state) needs 1.4+
  required_version = ">= 1.4.0"

  required_providers {
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
  }
}

provider "aws" {
  region = var.aws_region
}
