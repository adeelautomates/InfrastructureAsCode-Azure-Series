variable "name" {
  description = "Name of the Key Vault secret."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault."
  type        = string
}

variable "password_length" {
  description = "Length of the generated password."
  type        = number
  default     = 16
}

variable "min_lower" {
  description = "Minimum number of lowercase characters."
  type        = number
  default     = 1
}

variable "min_upper" {
  description = "Minimum number of uppercase characters."
  type        = number
  default     = 1
}

variable "min_numeric" {
  description = "Minimum number of numeric characters."
  type        = number
  default     = 1
}

variable "min_special" {
  description = "Minimum number of special characters."
  type        = number
  default     = 1
}

variable "override_special" {
  description = "Special characters allowed in the generated password."
  type        = string
  default     = "!#$*"
}
