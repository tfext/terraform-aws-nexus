data "aws_efs_file_system" "efs" {
  tags = {
    Name = var.efs_file_system_name
  }
}

resource "aws_efs_access_point" "nexus" {
  file_system_id = data.aws_efs_file_system.efs.file_system_id

  root_directory {
    path = "/shared-data/${local.name}"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "777"
    }
  }
}

