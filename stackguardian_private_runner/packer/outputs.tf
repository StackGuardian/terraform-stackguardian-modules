/*----------------------------------+
 | Packer AMI Machine Image Builder |
 +----------------------------------*/
output "ami_id" {
  value = data.external.packer_ami_id.result["ami_id"]
}
