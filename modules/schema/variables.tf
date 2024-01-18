variable "rubygems" {
  type        = bool
  default     = false
  nullable    = false
  description = "Create Rubygems repositories"
}

variable "docker" {
  type        = bool
  default     = false
  nullable    = false
  description = "Create Docker repositories"
}

variable "users" {
  type = list(object({
    name       = string
    first_name = optional(string)
    last_name  = optional(string)
    email      = string
    role       = string
  }))
  default     = []
  nullable    = false
  description = "List of users to create and assign roles"
}
