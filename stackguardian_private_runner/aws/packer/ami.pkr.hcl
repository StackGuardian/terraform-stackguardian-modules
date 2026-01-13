variable "base_ami" {}
variable "os_family" {}
variable "os_version" {}
variable "update_os_before_install" {}
variable "region" {}
variable "ssh_username" {}
variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "proxy_url" {}
variable "terraform_version" {}
variable "terraform_versions" {}
variable "opentofu_version" {}
variable "opentofu_versions" {}
variable "user_script" {}
variable "vpc_id" {}
variable "deregistration_protection_enabled" {}
variable "deregistration_protection_with_cooldown" {}

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
    enabled = var.deregistration_protection_enabled
    with_cooldown = var.deregistration_protection_with_cooldown
  }

  vpc_id        = var.vpc_id
  subnet_id     = var.private_subnet_id != "" ? var.private_subnet_id : var.public_subnet_id
  ssh_username  = var.ssh_username

  # Only set public IP and security group source for public subnets
  associate_public_ip_address = var.public_subnet_id != ""
  temporary_security_group_source_public_ip = var.public_subnet_id != ""

  shutdown_behavior = "terminate"
}

build {
  sources = ["source.amazon-ebs.this"]

  provisioner "shell" {
    script = "scripts/setup.sh"
    environment_vars = [
      "OS_FAMILY=${var.os_family}",
      "UPDATE_OS=${var.update_os_before_install}",
      "TERRAFORM_VERSION=${var.terraform_version}",
      "TERRAFORM_VERSIONS=${var.terraform_versions}",
      "OPENTOFU_VERSION=${var.opentofu_version}",
      "OPENTOFU_VERSIONS=${var.opentofu_versions}",
      "USER_SCRIPT=${var.user_script}",
      "PRIVATE_NETWORK=${var.private_subnet_id != "" ? "true" : "false"}",
      "PROXY_URL=${var.proxy_url}"
    ]
  }
}
