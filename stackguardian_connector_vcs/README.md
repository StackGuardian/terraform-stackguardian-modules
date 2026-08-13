# StackGuardian VCS Connector

Creates typed GitHub, GitLab, or Bitbucket connectors. Configure the StackGuardian provider in the calling root. VCS credentials are sensitive and retained in Terraform state.

```hcl
module "vcs" {
  source = "./stackguardian_connector_vcs"
  vcs_connectors = {
    github = {
      name = "github"
      kind = "GITHUB_COM"
      github = { githubCreds = var.github_credential }
    }
  }
}
```

Output: `connector_vcs`.
