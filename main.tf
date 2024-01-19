module "base" {
  source = "github.com/tfext/terraform-aws-base"
}

module "tagging" {
  source       = "github.com/tfext/terraform-utilities-tagging"
  environments = false
}

locals {
  name              = "nexus"
  nexus_image       = "sonatype/nexus3"
  nexus_port        = 8081
  docker_ports      = [5000, 5001]
  all_ports         = concat([local.nexus_port], local.docker_ports)
  load_balancer_map = { for lb in var.load_balancers : lb.name => lb }
}

resource "aws_cloudwatch_log_group" "nexus" {
  name              = var.log_group
  retention_in_days = 3
}

resource "random_password" "initial_password" {
  length  = 15
  special = true
}

resource "null_resource" "echo_password" {
  provisioner "local-exec" {
    command = "echo 'Nexus admin password (change immediately): ${nonsensitive(random_password.initial_password.result)}'"
  }
  depends_on = [random_password.initial_password]
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    sid       = "efs"
    resources = [data.aws_efs_file_system.efs.arn]
    actions = [
      "efs:*"
    ]
  }
}

module "container_definition" {
  source          = "github.com/tfext/terraform-aws-ecs-container-definition"
  name            = local.name
  image           = local.nexus_image
  image_tag       = var.nexus_version
  memory_required = var.memory
  cpu             = 1

  environment = {
    "INSTALL4J_ADD_VM_PARAMS"         = "-Xms${var.memory}m -Xmx${var.memory}m -XX:MaxDirectMemorySize=${var.memory}m -Djava.util.prefs.userRoot=$${NEXUS_DATA}/javaprefs"
    "NEXUS_SECURITY_INITIAL_PASSWORD" = random_password.initial_password.result
    "NEXUS_SECURITY_RANDOMPASSWORD"   = "false"
  }

  ports = concat(
    [{
      port         = local.nexus_port
      public_port  = 443
      health_check = { status_codes = "200-499" }
    }],
    var.docker ? [for p in local.docker_ports : {
      port = p
      health_check = {
        status_codes = "200-499"
        threshold    = 2
        interval     = 300
      }
    }] : []
  )

  shared_data = {
    efs_id          = data.aws_efs_file_system.efs.file_system_id
    access_point_id = aws_efs_access_point.nexus.id
    mount_path      = "/nexus-data"
  }

  aws_logging = {
    group = aws_cloudwatch_log_group.nexus.name
  }

  depends_on = [
    aws_lb_listener.nexus_port
  ]
}

module "service" {
  source          = "github.com/tfext/terraform-aws-ecs-service"
  name            = local.name
  cluster         = var.ecs_cluster
  containers      = [module.container_definition]
  role_policy     = data.aws_iam_policy_document.role_policy.json
  singleton       = true
  wait_for_stable = false # Takes too long...

  load_balancers = var.load_balancers

  depends_on = [
    aws_lb_listener.nexus_port,
    aws_security_group_rule.nexus_port
  ]
}
