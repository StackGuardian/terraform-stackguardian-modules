# Build Lambda package from source repository

resource "null_resource" "build_lambda" {
  triggers = {
    repo_url    = var.autoscaler_repo.url
    repo_branch = var.autoscaler_repo.branch
    build_hash  = filemd5("${path.module}/scripts/build_lambda.sh")
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/scripts/build_lambda.sh"
    interpreter = ["bash", "-c"]
    environment = {
      REPO_URL    = var.autoscaler_repo.url
      REPO_BRANCH = var.autoscaler_repo.branch
      BUILD_DIR   = local.lambda_build_dir
    }
  }
}

# Create zip from built package
data "archive_file" "lambda" {
  depends_on = [null_resource.build_lambda]

  type        = "zip"
  source_dir  = "${local.lambda_build_dir}/package"
  output_path = "${local.lambda_build_dir}/lambda.zip"
}
