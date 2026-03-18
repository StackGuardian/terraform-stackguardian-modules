locals {
  ssh_username = var.os.ssh_username != "" ? var.os.ssh_username : "ubuntu"
}
