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

  # The AMI built by this module, as recorded in state. Packer runs on the first
  # apply and then only when packer_config.rebuild_ami_token changes, so this
  # value stays stable across re-plans.
  ami_id = terraform_data.ami_id.output
}
