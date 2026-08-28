locals {
  # Default SSH user per AMI family, mirroring aws/packer's own mapping.
  # os.ssh_username overrides it.
  ssh_usernames = {
    amazon = "ec2-user"
    ubuntu = "ubuntu"
    rhel   = "ec2-user"
  }

  ssh_username = (
    var.os.ssh_username != ""
    ? var.os.ssh_username
    : local.ssh_usernames[var.os.family]
  )
}
