variable "base_ami" {}
variable "os_family" {}
variable "os_version" {}
variable "region" {}
variable "ssh_username" {}
variable "subnet_id" {}
variable "terraform_version" {}
variable "terraform_versions" {}
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
  ami_description = <<EOT
    Custom AMI built for StackGuardian Private Runner.
    This AMI is based on ${var.os_family}${var.os_family != "amazon" ? "version ${var.os_version}." : "."}
  EOT

  region        = var.region
  instance_type = "t3.medium"
  ami_virtualization_type = "hvm"

  source_ami    = var.base_ami

  deregistration_protection {
    enabled = true
    with_cooldown = true
  }

  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  ssh_username  = var.ssh_username
  temporary_security_group_source_public_ip = true
  associate_public_ip_address = true

  shutdown_behavior = "terminate"
}

build {
  sources = ["source.amazon-ebs.this"]

  provisioner "shell" {
    script = "scripts/sh/setup.sh"
    environment_vars = [
      "OS_FAMILY=${var.os_family}",
      "TERRAFORM_VERSION=${var.terraform_version}",
      "TERRAFORM_VERSIONS=${var.terraform_versions}",
      "USER_SCRIPT=${var.user_script}"
    ]
  }
}
