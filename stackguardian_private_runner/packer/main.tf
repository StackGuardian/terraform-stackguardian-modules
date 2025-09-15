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
      BASE_AMI                                = data.aws_ami.this.id
      OS_FAMILY                               = var.os.family
      OS_VERSION                              = var.os.family != "amazon" ? var.os.version : ""
      UPDATE_OS                               = var.os.update_os_before_install
      PACKER_VERSION                          = var.packer_config.version
      REGION                                  = var.aws_region
      SSH_USERNAME                            = local.ssh_usernames[var.os.family]
      PUBLIC_SUBNET_ID                        = var.network.public_subnet_id
      PRIVATE_SUBNET_ID                       = var.network.private_subnet_id
      PROXY_URL                               = var.network.proxy_url
      USER_SCRIPT                             = var.os.user_script
      TERRAFORM_VERSION                       = var.terraform.primary_version
      TERRAFORM_VERSIONS                      = join(" ", var.terraform.additional_versions)
      OPENTOFU_VERSION                        = var.opentofu.primary_version
      OPENTOFU_VERSIONS                       = join(" ", var.opentofu.additional_versions)
      VPC_ID                                  = var.network.vpc_id
      DEREGISTRATION_PROTECTION_ENABLED       = var.packer_config.deregistration_protection.enabled
      DEREGISTRATION_PROTECTION_WITH_COOLDOWN = var.packer_config.deregistration_protection.with_cooldown
    }
  }


  triggers = {
    timestamp = timestamp()
  }
}

# Conditional AMI cleanup resource
resource "null_resource" "ami_cleanup" {
  count = var.packer_config.cleanup_amis_on_destroy ? 1 : 0

  # Store AMI information as triggers so they're available during destroy
  triggers = {
    ami_id           = data.external.packer_ami_id.result["ami_id"]
    region           = var.aws_region
    delete_snapshots = var.packer_config.delete_snapshots
    script_path      = "${path.module}/scripts/cleanup_amis.sh"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sh ${self.triggers.script_path}"
    environment = {
      TERRAFORM_DESTROY = "true"
      TARGET_AMI_ID     = self.triggers.ami_id
      DELETE_SNAPSHOTS  = self.triggers.delete_snapshots
      REGION            = self.triggers.region
    }
  }

  depends_on = [null_resource.packer_build]
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
