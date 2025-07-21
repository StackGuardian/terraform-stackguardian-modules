variable "os_family" {}
variable "os_version" {}
variable "ssh_username" {}
variable "base_ami" {}
variable "region" {}
variable "subnet_id" {}
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
  ami_name      = "sg-runner-ami-${var.os_family}${var.os_version}-{{timestamp}}"
  instance_type = "t3.medium"
  region        = var.region
  source_ami    = var.base_ami
  ssh_username  = var.ssh_username
  subnet_id     = var.subnet_id
  vpc_id        = var.vpc_id
}

build {
  sources = ["source.amazon-ebs.this"]

  provisioner "shell" {
    script = "templates/install_dependencies.sh"
    environment_vars = [
      "OS_FAMILY=${var.os_family}",
    ]
  }
}
