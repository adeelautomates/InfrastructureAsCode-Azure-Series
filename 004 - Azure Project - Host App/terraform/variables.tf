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
      acr_rg         = string
      acr_name       = string
      private_dns_rg = string
    })
  })
}

variable "resource" {
  description = "Resource-specific configuration."
  type = object({
    storage = object({
      type       = string
      tier       = string
      containers = set(string)
    })
    sql = object({
      adminUPN = string
      database = object({
        sku         = string
        max_size_gb = number
      })
    })
    container = object({
      subnet_address = string
      app = object({
        cpu          = number
        memory       = string
        min_replicas = number
        max_replicas = number
        image_tag    = string
        port         = number
      })
    })
  })
}