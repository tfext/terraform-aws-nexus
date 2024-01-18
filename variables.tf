variable "nexus_version" {
  type        = string
  default     = "3.64.0"
  description = "Version of Nexus to deploy"
}

variable "memory" {
  type        = number
  default     = 2048
  description = "Amount of memory to require"
}

variable "docker" {
  type        = bool
  default     = false
  description = "Enable Docker support"
}

variable "log_group" {
  type        = string
  default     = "nexus"
  description = "CloudWatch log group name"
}

variable "efs_file_system_name" {
  type        = string
  description = "Name of EFS file system to use for Nexus storage"
}

variable "load_balancers" {
  type = list(object({
    name          = string
    short_name    = optional(string)
    dns_zone      = string
    dns_subdomain = string
    priority      = optional(number)
    vpc           = string
  }))
  nullable    = false
  default     = []
  description = "List of load balancer names to add Nexus to"
}

variable "certificate_domain" {
  type        = string
  description = "Domain for certificate to use on load balancer listener"
}

variable "ecs_cluster" {
  type        = string
  description = "Name of the ECS cluster to deploy in"
}
