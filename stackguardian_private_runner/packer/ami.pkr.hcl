variable "base_ami" {}
variable "os_family" {}
variable "os_version" {}
variable "region" {}
variable "ssh_username" {}
variable "subnet_id" {}
variable "terraform_version" {}
variable "user_script" {}
variable "vpc_id" {}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "this" {
  ami_name      = "SG-RUNNER-ami-${var.os_family}${var.os_version}-{{timestamp}}"
  instance_type = "t3.medium"
  region        = var.region
  source_ami    = var.base_ami
  ssh_username  = var.ssh_username
  subnet_id     = var.subnet_id
  vpc_id        = var.vpc_id
  temporary_security_group_source_public_ip = true
}

build {
  sources = ["source.amazon-ebs.this"]

  provisioner "shell" {
    script = "scripts/setup.sh"
    environment_vars = [
      "OS_FAMILY=${var.os_family}",
      "TERRAFORM_VERSION=${var.terraform_version}",
      "USER_SCRIPT=${var.user_script}"
    ]
  }
}
