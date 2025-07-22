/*---------------------------------+
 | StackGuardian Resources Outputs |
 +---------------------------------*/
output "storage_backend_name" {
  value = aws_s3_bucket.this.bucket
}

output "runner_group" {
  value = stackguardian_runner_group.this.resource_name
}

/*-----------------------+
 | AWS Resources Outputs |
 +-----------------------*/
# output "ec2_instance_id" {
#   value = aws_instance.this.id
# }

# output "ec2_instance_public_ip" {
#   value = var.associate_public_ip_address ? aws_instance.this.public_ip : null
# }

output "lambda_function_name" {
  value = aws_lambda_function.autoscale.function_name
}
