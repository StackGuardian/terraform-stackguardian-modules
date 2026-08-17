mock_provider "stackguardian" {}

variables {
  subject = "developer@example.invalid"
  roles   = ["developer", "auditor"]
}

run "assigns_all_roles_in_one_resource" {
  command = plan

  assert {
    condition     = output.user == "developer@example.invalid" && output.roles == tolist(["developer", "auditor"])
    error_message = "One subject assignment must preserve every requested role."
  }
}

run "rejects_empty_role_list" {
  command = plan

  variables {
    roles = []
  }

  expect_failures = [var.roles]
}

run "rejects_duplicate_role_list" {
  command = plan

  variables {
    roles = ["developer", "developer"]
  }

  expect_failures = [var.roles]
}
