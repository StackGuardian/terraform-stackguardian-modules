/*---------------------------+
 | AMI Selection and Mapping  |
 +---------------------------*/
locals {
  ami_owners = {
    amazon = "amazon"
    ubuntu = "099720109477" # Canonical
    rhel   = "309956199498" # Red Hat
  }

  ami_name_patterns = {
    amazon = "amzn2-ami-hvm-*-gp2"
    ubuntu = "ubuntu/images/hvm-ssd/ubuntu-*${var.os.version}*-server-*"
    rhel   = "RHEL-${var.os.version}*"
  }

  ssh_usernames = {
    amazon = var.os.ssh_username != "" ? var.os.ssh_username : "ec2-user"
    ubuntu = var.os.ssh_username != "" ? var.os.ssh_username : "ubuntu"
    rhel   = var.os.ssh_username != "" ? var.os.ssh_username : "ec2-user"
  }
}

/*-------------------+
 | AMI Build Records |
 +-------------------*/
locals {
  # Name given to AMIs built by this module (see ami.pkr.hcl)
  runner_ami_name_pattern = "${var.ami_name_prefix}-${var.os.family}${var.os.family != "amazon" ? var.os.version : ""}-*"

  # Whether to build at all. An existing_ami_id turns every build resource off.
  build_ami = var.existing_ami_id == ""

  # The AMI built by this module, as recorded in state. Packer runs on the first
  # apply and then only when packer_config.rebuild_ami_token changes, so this
  # value stays stable across re-plans. Null when the build was skipped.
  built_ami_id = one(terraform_data.ami_id[*].output)

  # What the module reports: the AMI it was handed, otherwise the one it built.
  ami_id = (
    var.existing_ami_id != ""
    ? var.existing_ami_id
    : (local.built_ami_id == null ? "" : local.built_ami_id)
  )
}
