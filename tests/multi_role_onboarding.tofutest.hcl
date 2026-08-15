mock_provider "stackguardian" {}
mock_provider "aws" {}
mock_provider "azurerm" {}
mock_provider "azuread" {}
mock_provider "google" {}

variables {
  stackguardian_api_key  = "sgu_testkey"
  stackguardian_org_name = "contract-org"
  workflow_groups        = ["engineering", "platform"]
  vcs_connectors = {
    github = {
      kind = "GITHUB_COM"
      name = "github"
      github = {
        githubCreds = "test-credential"
      }
    }
  }
  roles = {
    developer = {
      workflow_groups = ["engineering"]
      vcs_connectors  = ["github"]
    }
    auditor = {
      workflow_groups = ["engineering", "platform"]
      vcs_connectors  = ["github"]
    }
  }
  subjects = {
    "developer@example.invalid" = {
      roles = ["developer", "auditor"]
    }
    "okta/platform-engineers" = {
      entity_type = "GROUP"
      roles       = ["auditor"]
    }
  }
}

run "provisions_keyed_roles_and_multi_role_subjects" {
  command = plan

  assert {
    condition     = tolist(output.role_permissions["developer"]["GET/api/v1/orgs/contract-org/wfgrps/<wfGrp>/"].paths["<wfGrp>"]) == tolist(["engineering", "engineering/.*"])
    error_message = "Roles must resolve workflow-group references through keyed module instances."
  }

  assert {
    condition     = tolist(output.role_permissions["auditor"]["GET/api/v1/orgs/contract-org/integrations/<integration>/"].paths["<integration>"]) == tolist(["github"])
    error_message = "Roles must resolve keyed VCS connector references."
  }

  assert {
    condition     = tolist(output.subject_roles["developer@example.invalid"]) == tolist(["developer", "auditor"])
    error_message = "A subject must receive all configured roles in one assignment."
  }

  assert {
    condition     = tolist(output.subject_roles["okta/platform-engineers"]) == tolist(["auditor"])
    error_message = "A group subject must receive its configured role."
  }
}
