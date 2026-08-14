mock_provider "stackguardian" {}

variables {
  org_name         = "contract-org"
  role_name        = "contract-role"
  workflow_groups  = ["platform", "applications"]
  cloud_connectors = ["cloud-one", "cloud-two"]
  vcs_connectors   = ["vcs-one"]
  template_list    = ["template-one", "template-two"]
}

run "builds_scoped_v4_permissions" {
  command = plan

  assert {
    condition     = output.role == "contract-role"
    error_message = "The role output must preserve the supplied role name."
  }

  assert {
    condition     = output.allowed_permissions["GET/api/v1/orgs/contract-org/wfgrps/<wfGrp>/"].paths["<wfGrp>"] == ["platform", "platform/.*", "applications", "applications/.*"]
    error_message = "Workflow groups must use exact and nested positional v4 paths."
  }

  assert {
    condition     = output.allowed_permissions["GET/api/v1/orgs/contract-org/wfgrps/<wfGrp>/wfs/<wf>/"].paths["<wf>"] == [".*", ".*", ".*", ".*"]
    error_message = "Workflow wildcard paths must match the workflow-group path count."
  }

  assert {
    condition     = output.allowed_permissions["GET/api/v1/orgs/contract-org/integrations/<integration>/"].paths["<integration>"] == tolist(["cloud-one", "cloud-two", "vcs-one"])
    error_message = "Integration permissions must contain only supplied connector names."
  }

  assert {
    condition     = output.allowed_permissions["GET/api/v1/templatetypes/<templateType>/<org>/<template>/"].paths["<template>"] == tolist(["template-one", "template-two"])
    error_message = "Template permissions must contain only supplied template names."
  }

  assert {
    condition     = alltrue([for url in keys(output.allowed_permissions) : !strcontains(url, "/reports/") && !strcontains(url, "/audit_logs/") && !strcontains(url, "/apiaccesses/") && !strcontains(url, "/roles/") && !strcontains(url, "/policies/") && !strcontains(url, "/runnergroups/") && !strcontains(url, "/subscriptions/")])
    error_message = "Role permissions must not include broad administrative endpoints."
  }
}

run "omits_workflow_permissions_for_connector_only_role" {
  command = plan

  variables {
    workflow_groups  = []
    cloud_connectors = ["cloud-one"]
    vcs_connectors   = []
    template_list    = []
  }

  assert {
    condition     = alltrue([for url in keys(output.allowed_permissions) : !strcontains(url, "/wfgrps/")])
    error_message = "A role without workflow groups must not receive workflow permissions."
  }
}

run "omits_workflow_permissions_for_template_only_role" {
  command = plan

  variables {
    workflow_groups  = []
    cloud_connectors = []
    vcs_connectors   = []
    template_list    = ["template-one"]
  }

  assert {
    condition     = tolist(keys(output.allowed_permissions)) == tolist(["DELETE/api/v1/templatetypes/<templateType>/<org>/<template>/", "GET/api/v1/templatetypes/<templateType>/<org>/<template>/", "PATCH/api/v1/templatetypes/<templateType>/<org>/<template>/"])
    error_message = "A template-only role must contain only template permissions."
  }
}

run "rejects_role_without_scopes" {
  command = plan

  variables {
    workflow_groups  = []
    cloud_connectors = []
    vcs_connectors   = []
    template_list    = []
  }

  expect_failures = [stackguardian_rolev4.role]
}
