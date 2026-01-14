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

