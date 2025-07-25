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

locals {
  runner_ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.this.id
}
