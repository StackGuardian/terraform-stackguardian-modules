# Build Lambda package from source repository

resource "terraform_data" "build_lambda" {
  triggers_replace = [
    var.autoscaler_repo.url,
    var.autoscaler_repo.branch,
    filemd5("${path.module}/scripts/build_lambda.sh")
  ]

  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/build_lambda.sh"
    environment = {
      REPO_URL    = var.autoscaler_repo.url
      REPO_BRANCH = var.autoscaler_repo.branch
      BUILD_DIR   = local.lambda_build_dir
    }
  }
}
