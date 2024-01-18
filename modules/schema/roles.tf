locals {
  read_privileges = [
    "nx-repository-view-*-*-browse",
    "nx-repository-view-*-*-read",
  ]
  write_privileges = flatten([for repo in local.internal_repositories : [
    "nx-repository-view-${repo.type}-${repo.name}-add",
    "nx-repository-view-${repo.type}-${repo.name}-edit"
  ]])

  roles = {
    developer = {
      privileges = concat(local.read_privileges, local.write_privileges)
    }
    build = {
      privileges = concat(local.read_privileges, local.write_privileges)
    }
    test = {
      privileges = local.read_privileges
    }
    deploy = {
      privileges = local.read_privileges
    }
  }
}

resource "nexus_security_role" "role" {
  for_each    = local.roles
  roleid      = each.key
  name        = each.key
  description = try(each.value.description, title(each.key))
  privileges  = try(each.value.privileges, [])
}
