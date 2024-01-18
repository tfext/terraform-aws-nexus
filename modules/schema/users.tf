locals {
  user_map = { for u in var.users : u.name => u }
}

resource "nexus_security_user" "user" {
  for_each  = local.user_map
  userid    = each.value.name
  firstname = coalesce(each.value.first_name, each.value.name)
  lastname  = coalesce(each.value.last_name, each.value.name)
  email     = each.value.email
  password  = random_password.user[each.key].result
  roles     = [each.value.role]

  lifecycle {
    ignore_changes = [password]
  }

  depends_on = [ nexus_security_role.role ]
}

resource "random_password" "user" {
  for_each = local.user_map
  length   = 15
}

resource "null_resource" "echo_password" {
  for_each = local.user_map
  provisioner "local-exec" {
    command = "echo 'New user ${each.key} temp password: ${nonsensitive(random_password.user[each.key].result)}'"
  }
}
