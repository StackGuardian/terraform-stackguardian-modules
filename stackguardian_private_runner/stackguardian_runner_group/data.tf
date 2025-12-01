# Data sources for existing runner group (when mode = "existing")

data "stackguardian_runner_group" "existing" {
  count = var.mode == "existing" ? 1 : 0

  resource_name = var.existing_runner_group_name
}

data "stackguardian_runner_group_token" "existing" {
  count = var.mode == "existing" ? 1 : 0

  resource_name = var.existing_runner_group_name
}

# Data source for token when creating new runner group
data "stackguardian_runner_group_token" "created" {
  count = var.mode == "create" ? 1 : 0

  resource_name = stackguardian_runner_group.this[0].resource_name

  depends_on = [stackguardian_runner_group.this]
}
