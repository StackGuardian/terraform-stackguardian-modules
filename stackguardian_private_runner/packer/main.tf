locals {
  ami_owners = {
    amazon = "amazon"
    ubuntu = "099720109477" # Canonical
    rhel   = "309956199498" # Red Hat
  }

  ami_name_patterns = {
    amazon = "amzn2-ami-hvm-*-x86_64-gp2"
    ubuntu = "ubuntu/images/hvm-ssd/ubuntu-*${var.os_version}-amd64-server-*"
    rhel   = "RHEL-${var.os_version}*"
  }

  ssh_usernames = {
    amazon = "ec2-user"
    ubuntu = "ubuntu"
    rhel   = "ec2-user"
  }
}

# Fetch the latest AMI based on the OS family and version
data "aws_ami" "this" {
  most_recent = true
  owners      = [local.ami_owners[var.os_family]]

  filter {
    name   = "name"
    values = [local.ami_name_patterns[var.os_family]]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Build custom AMI using Packer
resource "null_resource" "packer_build" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/build_ami.sh"
    environment = {
      BASE_AMI          = data.aws_ami.this.id
      OS_FAMILY         = var.os_family
      OS_VERSION        = var.os_family != "amazon" ? var.os_version : ""
      PACKER_VERSION    = var.packer_version
      REGION            = var.aws_region
      SSH_USERNAME      = local.ssh_usernames[var.os_family]
      SUBNET_ID         = var.public_subnet_id
      USER_SCRIPT       = var.user_script
      TERRAFORM_VERSION = var.terraform_version
      VPC_ID            = var.vpc_id
    }
  }

  triggers = {
    build_hash    = filemd5("${path.module}/scripts/build_ami.sh")
    setup_hash    = filemd5("${path.module}/scripts/setup.sh")
    template_hash = filemd5("${path.module}/ami.pkr.hcl")
  }
}

# Parse the AMI ID from the Packer output
data "external" "packer_ami_id" {
  program = [
    "bash",
    "-c",
    "grep 'artifact,0,id' packer_manifest.log | tail -1 | cut -d, -f6 | cut -d: -f2 | xargs -I{} echo '{\"ami_id\": \"{}\"}'"
  ]

  depends_on = [null_resource.packer_build]
}
