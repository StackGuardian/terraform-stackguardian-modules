/*----------------------------------+
 | Packer AMI Machine Image Builder |
 +----------------------------------*/
output "ami_info" {
  description = "Comprehensive AMI information for tracking and cleanup"
  value = {
    ami_id     = data.external.packer_ami_id.result["ami_id"]
    region     = var.aws_region
    os_family  = var.os.family
    os_version = var.os.version
    timestamp  = formatdate("YYYY-MM-DD-hhmm", timestamp())
    ami_name   = "SG-RUNNER-ami-${var.os.family}${var.os.family != "amazon" ? var.os.version : ""}-*"
    deregistration_protection = {
      enabled       = var.packer_config.deregistration_protection.enabled
      with_cooldown = var.packer_config.deregistration_protection.with_cooldown
    }
    cleanup_settings = {
      automatic_cleanup = var.packer_config.cleanup_amis_on_destroy
      delete_snapshots  = var.packer_config.delete_snapshots
    }
  }
}

output "cleanup_commands" {
  description = "AWS CLI commands for manual AMI cleanup"
  value = {
    check_protection   = "aws ec2 describe-image-attribute --region ${var.aws_region} --image-id ${data.external.packer_ami_id.result["ami_id"]} --attribute deregistrationProtection"
    disable_protection = var.packer_config.deregistration_protection.enabled ? "aws ec2 disable-image-deregistration-protection --region ${var.aws_region} --image-id ${data.external.packer_ami_id.result["ami_id"]}" : "# Protection not enabled"
    deregister_ami     = "aws ec2 deregister-image --region ${var.aws_region} --image-id ${data.external.packer_ami_id.result["ami_id"]}"
    list_snapshots     = "aws ec2 describe-images --region ${var.aws_region} --image-ids ${data.external.packer_ami_id.result["ami_id"]} --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text"
    delete_snapshots   = var.packer_config.delete_snapshots ? "aws ec2 describe-images --region ${var.aws_region} --image-ids ${data.external.packer_ami_id.result["ami_id"]} --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text | xargs -n1 aws ec2 delete-snapshot --region ${var.aws_region} --snapshot-id" : "# Snapshot deletion disabled"
    cleanup_note       = var.packer_config.deregistration_protection.with_cooldown ? "NOTE: If cooldown is enabled, wait 24 hours after disabling protection before deregistering" : "No cooldown period configured"
  }
}
