# Fetch the latest AMI based on the OS family and version
data "aws_ami" "this" {
  count = local.build_ami ? 1 : 0

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
#
# Created once per state, so Packer runs on the first apply only. Change
# packer_config.rebuild_ami_token to any new value to replace this resource and
# build a fresh AMI; re-plans with an unchanged token do nothing.
resource "null_resource" "packer_build" {
  count = local.build_ami ? 1 : 0

  provisioner "local-exec" {
    command     = "sh ../../packer/scripts/build.sh"
    working_dir = path.module
    environment = {
      # Drives the shared build script itself
      PACKER_VERSION  = var.packer_config.version
      PACKER_TEMPLATE = "./ami.pkr.hcl"

      # Packer reads PKR_VAR_<name> natively, so these reach ami.pkr.hcl
      # without the build script having to know the per-cloud variable list.
      PKR_VAR_base_ami                                = data.aws_ami.this[0].id
      PKR_VAR_ami_name_prefix                         = var.ami_name_prefix
      PKR_VAR_os_family                               = var.os.family
      PKR_VAR_os_version                              = var.os.family != "amazon" ? var.os.version : ""
      PKR_VAR_update_os_before_install                = var.os.update_os_before_install
      PKR_VAR_region                                  = var.aws_region
      PKR_VAR_ssh_username                            = local.ssh_usernames[var.os.family]
      PKR_VAR_public_subnet_id                        = var.network.public_subnet_id
      PKR_VAR_private_subnet_id                       = var.network.private_subnet_id
      PKR_VAR_proxy_url                               = var.network.proxy_url
      PKR_VAR_user_script                             = var.os.user_script
      PKR_VAR_terraform_version                       = var.terraform.primary_version
      PKR_VAR_terraform_versions                      = join(" ", var.terraform.additional_versions)
      PKR_VAR_opentofu_version                        = var.opentofu.primary_version
      PKR_VAR_opentofu_versions                       = join(" ", var.opentofu.additional_versions)
      PKR_VAR_sg_runner_pre_release                   = var.sg_runner.pre_release
      PKR_VAR_vpc_id                                  = var.network.vpc_id
      PKR_VAR_deregistration_protection_enabled       = var.packer_config.deregistration_protection.enabled
      PKR_VAR_deregistration_protection_with_cooldown = var.packer_config.deregistration_protection.with_cooldown
    }
  }


  triggers = {
    rebuild_token = var.packer_config.rebuild_ami_token
  }
}

# Parse the AMI ID out of the Packer build log
#
# Only meaningful right after a build. It returns an empty AMI ID when the log is
# missing (fresh checkout, CI runner) instead of failing the plan, because the
# recorded AMI ID is read from state via terraform_data.ami_id below.
data "external" "packer_ami_id" {
  count = local.build_ami ? 1 : 0

  program = [
    "sh",
    "-c",
    "ami_id=$(grep 'artifact,0,id' ${path.module}/packer_manifest.log 2>/dev/null | tail -1 | cut -d, -f6 | cut -d: -f2); printf '{\"ami_id\": \"%s\"}' \"$ami_id\""
  ]

  depends_on = [null_resource.packer_build]
}

# Record the built AMI ID in state
#
# input is only re-read when a build runs (replace_triggered_by); ignore_changes
# keeps the recorded ID untouched by later plans, even if the build log is stale
# or gone.
resource "terraform_data" "ami_id" {
  count = local.build_ami ? 1 : 0

  input = data.external.packer_ami_id[0].result["ami_id"]

  lifecycle {
    ignore_changes       = [input]
    replace_triggered_by = [null_resource.packer_build[0]]
  }
}

# Conditional AMI cleanup resource
#
# Tracks the AMI this module built, so a destroy never deregisters an image it
# did not create. Re-keyed by a rebuild, which deregisters the superseded AMI.
# Never runs for an AMI passed in through existing_ami_id: the module did not
# build it, so it has no business deregistering it.
resource "null_resource" "ami_cleanup" {
  count = local.build_ami && var.packer_config.cleanup_amis_on_destroy ? 1 : 0

  # Store AMI information as triggers so they're available during destroy
  triggers = {
    ami_id           = local.ami_id
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
}

# The build resources gained a count when existing_ami_id was introduced. These
# keep a state written before that from re-keying, which would otherwise destroy
# and rebuild the AMI on the next apply.
moved {
  from = null_resource.packer_build
  to   = null_resource.packer_build[0]
}

moved {
  from = terraform_data.ami_id
  to   = terraform_data.ami_id[0]
}
