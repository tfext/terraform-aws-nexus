terraform {
  required_providers {
    nexus = {
      source = "datadrivers/nexus"
    }
  }
}

locals {
  rubygems_count = var.rubygems ? 1 : 0
  docker_count = var.docker ? 1 : 0
  docker_ports = {
    read  = 5000
    write = 5001
  }
}
