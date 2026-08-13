resource "stackguardian_connector" "vcs" {
  for_each = {
    for key, connector in var.vcs_connectors : nonsensitive(key) => connector
  }

  resource_name = each.value.name
  description   = "StackGuardian ${each.value.kind} VCS connector"
  settings = {
    kind = each.value.kind
    config = [merge(
      each.value.github != null ? { github_creds = jsonencode(each.value.github) } : {},
      each.value.gitlab != null ? { gitlab_creds = jsonencode(each.value.gitlab) } : {},
      each.value.bitbucket != null ? { bitbucket_creds = jsonencode(each.value.bitbucket) } : {}
    )]
  }
}
