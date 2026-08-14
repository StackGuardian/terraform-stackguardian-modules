resource "stackguardian_connector" "vcs" {
  for_each = toset(nonsensitive(keys(var.vcs_connectors)))

  resource_name = var.vcs_connectors[each.value].name
  description   = "StackGuardian ${var.vcs_connectors[each.value].kind} VCS connector"
  settings = {
    kind = var.vcs_connectors[each.value].kind
    config = [merge(
      var.vcs_connectors[each.value].github != null ? { github_creds = jsonencode(var.vcs_connectors[each.value].github) } : {},
      var.vcs_connectors[each.value].gitlab != null ? { gitlab_creds = jsonencode(var.vcs_connectors[each.value].gitlab) } : {},
      var.vcs_connectors[each.value].bitbucket != null ? { bitbucket_creds = jsonencode(var.vcs_connectors[each.value].bitbucket) } : {}
    )]
  }
}
