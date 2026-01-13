terraform {
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
