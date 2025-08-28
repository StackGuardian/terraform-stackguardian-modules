# Fetch the latest AMI based on the OS family and version
data "aws_ami" "this" {
  most_recent = true
  owners      = [local.ami_owners[var.os.family]]

  filter {
    name   = "name"
    values = [local.ami_name_patterns[var.os.family]]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Build custom AMI using Packer
resource "null_resource" "packer_build" {
  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/build_ami.sh"
    environment = {
      BASE_AMI           = data.aws_ami.this.id
      OS_FAMILY          = var.os.family
      OS_VERSION         = var.os.family != "amazon" ? var.os.version : ""
      UPDATE_OS          = var.os.update_os_before_install
      PACKER_VERSION     = var.packer_config.version
      REGION             = var.aws_region
      SSH_USERNAME       = local.ssh_usernames[var.os.family]
      SUBNET_ID          = var.network.public_subnet_id
      USER_SCRIPT        = var.packer_config.user_script
      TERRAFORM_VERSION  = var.terraform.primary_version
      TERRAFORM_VERSIONS = join(" ", var.terraform.additional_versions)
      OPENTOFU_VERSION   = var.opentofu.primary_version
      OPENTOFU_VERSIONS  = join(" ", var.opentofu.additional_versions)
      VPC_ID             = var.network.vpc_id
    }
  }

  triggers = {
    timestamp = timestamp()
  }
}

# Parse the AMI ID from the Packer output
data "external" "packer_ami_id" {
  program = [
    "sh",
    "-c",
    "grep 'artifact,0,id' packer_manifest.log | tail -1 | cut -d, -f6 | cut -d: -f2 | xargs -I{} echo '{\"ami_id\": \"{}\"}'"
  ]

  depends_on = [null_resource.packer_build]
}
