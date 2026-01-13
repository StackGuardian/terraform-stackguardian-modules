# Data source for runner group token
data "stackguardian_runner_group_token" "this" {
  runner_group_id = stackguardian_runner_group.this.resource_name

  depends_on = [stackguardian_runner_group.this]
}
