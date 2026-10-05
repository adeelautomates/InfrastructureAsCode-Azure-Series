variable "name" {
  description = "Name of the Storage Account."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group where the Storage Account will be deployed."
  type        = string
}

variable "location" {
  description = "Azure region where the Storage Account will be deployed."
  type        = string
}

variable "account_tier" {
  description = "Performance tier of the Storage Account."
  type        = string
  default     = "Standard"
}

variable "account_kind" {
  description = "Kind of Storage Account."
  type        = string
  default     = "StorageV2"
}

variable "account_replication_type" {
  description = "Replication type of the Storage Account."
  type        = string
  default     = "LRS"
}

variable "default_to_oauth_authentication" {
  description = "Use Microsoft Entra authentication by default."
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Enable Shared Key authentication."
  type        = bool
  default     = false
}

variable "allow_nested_items_to_be_public" {
  description = "Allow public access to containers and blobs."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access to the Storage Account."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the Storage Account."
  type        = map(string)
  default     = null
}

variable "containers" {
  description = "Storage account containers to create"
  type = map(object({
    access = string
  }))
  default = {}
}

variable "grant_deployer_blob_contributor" {
  description = "Grant the deploying identity Storage Blob Data Contributor."
  type        = bool
  default     = false
}