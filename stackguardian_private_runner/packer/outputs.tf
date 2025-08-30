/*----------------------------------+
 | Packer AMI Machine Image Builder |
 +----------------------------------*/
output "ami_id" {
  description = "The AMI ID created by Packer"
  value       = data.external.packer_ami_id.result["ami_id"]
}

output "ami_info" {
  description = "Comprehensive AMI information for tracking and cleanup"
  value = {
    ami_id     = data.external.packer_ami_id.result["ami_id"]
    region     = var.aws_region
    os_family  = var.os.family
    os_version = var.os.version
    timestamp  = formatdate("YYYY-MM-DD-hhmm", timestamp())
    ami_name   = "SG-RUNNER-ami-${var.os.family}${var.os.family != "amazon" ? var.os.version : ""}-*"
  }
}

output "cleanup_commands" {
  description = "AWS CLI commands for manual AMI cleanup"
  value = {
    list_amis      = "aws ec2 describe-images --region ${var.aws_region} --owners self --filters \"Name=name,Values=SG-RUNNER-ami-*\" --output table"
    deregister_ami = "aws ec2 deregister-image --region ${var.aws_region} --image-id ${data.external.packer_ami_id.result["ami_id"]}"
    list_snapshots = "aws ec2 describe-images --region ${var.aws_region} --image-ids ${data.external.packer_ami_id.result["ami_id"]} --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text"
  }
}
