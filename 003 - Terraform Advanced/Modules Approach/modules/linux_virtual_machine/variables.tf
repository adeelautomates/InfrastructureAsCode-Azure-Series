variable "name" {
  description = "Name of the Linux Virtual Machine."
  type        = string
}

variable "location" {
  description = "Azure region where the Virtual Machine will be deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group where the Virtual Machine will be deployed."
  type        = string
}

variable "size" {
  description = "SKU of the Virtual Machine."
  type        = string
}

variable "zone" {
  description = "Availability Zone for the Virtual Machine."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Administrator username for the Virtual Machine."
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the Virtual Machine."
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Resource ID of the subnet used by the Virtual Machine."
  type        = string
}

variable "custom_data" {
  description = "Base64 encoded custom data supplied to the Virtual Machine."
  type        = string
  default     = null
}

variable "os_disk_name" {
  description = "Name of the operating system disk."
  type        = string
}

variable "os_disk_caching" {
  description = "Caching mode for the operating system disk."
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Storage Account type used by the operating system disk."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  description = "Size of the operating system disk in GB."
  type        = number
  default     = 127
}

variable "image_publisher" {
  description = "Publisher of the Virtual Machine image."
  type        = string
}

variable "image_offer" {
  description = "Offer of the Virtual Machine image."
  type        = string
}

variable "image_sku" {
  description = "SKU of the Virtual Machine image."
  type        = string
}

variable "image_version" {
  description = "Version of the Virtual Machine image."
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags applied to the Virtual Machine."
  type        = map(string)
  default     = null
}
