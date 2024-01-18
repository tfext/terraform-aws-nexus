locals {
  internal_repositories = concat(
    [ for repo in nexus_repository_docker_hosted.docker_hosted : { name = repo.name, type = "docker" } ],
    [ for repo in nexus_repository_rubygems_hosted.rubygems_hosted : { name = repo.name, type = "rubygems" } ]
  )
}

resource "nexus_repository_rubygems_proxy" "rubygems_proxy" {
  count  = local.rubygems_count
  name   = "rubygems-proxy"
  online = true

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }

  proxy {
    remote_url       = "https://rubygems.org"
    content_max_age  = 1440
    metadata_max_age = 1440
  }

  negative_cache {
    enabled = true
    ttl     = 1440
  }

  http_client {
    blocked    = false
    auto_block = true
  }
}

resource "nexus_repository_rubygems_hosted" "rubygems_hosted" {
  count  = local.rubygems_count
  name   = "rubygems-internal"
  online = true

  storage {
    blob_store_name                = nexus_blobstore_file.internal.name
    strict_content_type_validation = true
  }

  depends_on = [nexus_blobstore_file.internal]
}

resource "nexus_repository_rubygems_group" "rubygems" {
  count  = local.rubygems_count
  name   = "rubygems"
  online = true

  group {
    member_names = [
      nexus_repository_rubygems_proxy.rubygems_proxy.0.name,
      nexus_repository_rubygems_hosted.rubygems_hosted.0.name,
    ]
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}

resource "nexus_repository_docker_proxy" "docker_proxy" {
  count  = local.docker_count
  name   = "docker-proxy"
  online = true

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }

  docker {
    force_basic_auth = false
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "HUB"
  }

  proxy {
    remote_url       = "https://registry-1.docker.io"
    content_max_age  = 1440
    metadata_max_age = 1440
  }

  negative_cache {
    enabled = true
    ttl     = 1440
  }

  http_client {
    blocked    = false
    auto_block = true
  }
}

resource "nexus_repository_docker_hosted" "docker_hosted" {
  count  = local.docker_count
  name   = "docker-internal"
  online = true

  docker {
    force_basic_auth = false
    v1_enabled       = false
    http_port        = 5001
  }

  storage {
    blob_store_name                = nexus_blobstore_file.internal.name
    strict_content_type_validation = true
  }

  depends_on = [nexus_blobstore_file.internal]
}

resource "nexus_repository_docker_group" "docker" {
  count  = local.docker_count
  name   = "docker"
  online = true

  docker {
    force_basic_auth = false
    v1_enabled       = false
    http_port        = 5000
  }

  group {
    member_names = [
      nexus_repository_docker_proxy.docker_proxy.0.name,
      nexus_repository_docker_hosted.docker_hosted.0.name
    ]
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}
