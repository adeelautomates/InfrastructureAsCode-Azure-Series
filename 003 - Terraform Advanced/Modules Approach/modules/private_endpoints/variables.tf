variable "name" {
  description = "Name of the Private Endpoint."
  type        = string
}

variable "location" {
  description = "Azure region where the Private Endpoint will be deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group where the Private Endpoint will be deployed."
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the subnet used by the Private Endpoint."
  type        = string
}

variable "private_service_connection_name" {
  description = "Name of the private service connection."
  type        = string
}

variable "private_connection_resource_id" {
  description = "Resource ID of the resource the Private Endpoint connects to."
  type        = string
}

variable "subresource_names" {
  description = "Subresource names used by the private service connection."
  type        = list(string)
}

variable "is_manual_connection" {
  description = "Whether the private service connection requires manual approval."
  type        = bool
  default     = false
}

variable "private_dns_zone_group_name" {
  description = "Name of the Private DNS Zone Group."
  type        = string
  default     = "default"
}

variable "private_dns_zone_ids" {
  description = "Resource IDs of the Private DNS Zones associated with the Private Endpoint."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to the Private Endpoint."
  type        = map(string)
  default     = null
}
