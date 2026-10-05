variable "config" {
  description = "Setup mandatory environment settings for your project."
  type = object({
    main = object({
      sub_id       = string
      env          = string
      region       = string
      region_short = string
      project_name = string
    })
    tags = object({
      owner1     = string
      owner2     = string
      costcentre = number
    })
    network = object({
      rg     = string
      vnet   = string
      subnet = string
    })
    mgmt = object({
      sub_id         = string
      kv_rg          = string
      kv_name        = string
      private_dns_rg = string
    })
  })
}

variable "storage" {
  description = "Configuration for the Azure Storage Account."
  type = object({
    tier              = string
    kind              = string
    type              = string
    default_oauth     = bool
    shared_key_access = bool
    containers = map(object({
      access = string
    }))
  })
}

variable "virtual_machine" {
  description = "Configuration for the Linux virtual machine."
  type = object({
    size     = string
    zone     = string
    username = string
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk = object({
      caching              = string
      storage_account_type = string
      disk_size_gb         = number
    })
  })
}

variable "owner_rbac" {
  description = "Role assignments granted to the project owners"
  type        = map(string)
}
