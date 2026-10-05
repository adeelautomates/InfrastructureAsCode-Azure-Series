
variable "sub_id" {
  type    = string
  default = "<enter ID>"
}

variable "env" {
  type = string
  validation {
    condition     = contains(local.allowed_env, var.env)
    error_message = "Must select environment: ${join(", ", local.allowed_env)}"
  }
}

variable "region" {
  type = string
  validation {
    condition     = contains(local.allowed_regions, replace(lower(var.region), " ", ""))
    error_message = "Must set region: ${join(", ", local.allowed_regions)}"
  }
}

variable "subnet_count" {
  type = number
  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 3
    error_message = "The count must be between 1 and 3."
  }
}

variable "subnets" {
  type = map(object({
    subnet_position                 = number
    delegation                      = optional(string)
    default_outbound_access_enabled = optional(bool)
  }))
}

variable "mandatory_tags" {
  type = object({
    owner1      = string
    owner2      = string
    cost-centre = number
  })
  validation {
    condition = (
      var.mandatory_tags.cost-centre >= 1000 && var.mandatory_tags.cost-centre <= 2000 &&
      alltrue([
        for email in [var.mandatory_tags.owner1, var.mandatory_tags.owner2]
        : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))
      ])
    )
    error_message = "owner1 and owner2 must be valid email addresses, and cost-centre must be between 1000 and 2000."
  }
}