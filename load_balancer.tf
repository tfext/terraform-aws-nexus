data "aws_lb" "load_balancer" {
  for_each = local.load_balancer_map
  name     = each.key
}

data "aws_acm_certificate" "nexus" {
  domain = var.certificate_domain
}

locals {
  lb_docker_ports = { for it in flatten([
    for lb in data.aws_lb.load_balancer : [
      for port in local.docker_ports : {
        lb             = lb
        security_group = one(lb.security_groups)
        port           = port
      }
    ]
    ]) : "${it.lb.name}-${it.port}" => it
  }
}

resource "aws_lb_listener" "nexus_port" {
  for_each          = local.lb_docker_ports
  load_balancer_arn = each.value.lb.arn
  port              = each.value.port
  certificate_arn   = data.aws_acm_certificate.nexus.arn
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_security_group_rule" "nexus_port" {
  for_each          = local.lb_docker_ports
  security_group_id = each.value.security_group
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "TCP"
  type              = "ingress"
  description       = "${each.value.lb.name} ${each.value.port} (${module.tagging.managed_by})"
  cidr_blocks       = [module.base.cidr_block_world]
}
