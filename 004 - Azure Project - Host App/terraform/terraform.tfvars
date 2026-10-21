config = {
  main = {
    sub_id       = "<enterSubID>"
    env          = "dev"
    region       = "canadacentral"
    region_short = "cc"
    project_name = "<yourProjectName>"
  }
  tags = {
    owner1     = "<enterUPN>"
    owner2     = "<enterUPN>"
    costcentre = 1001
  }
  network = {
    rg     = "rg-cc-dev-network"
    vnet   = "vnet-corpo-dev-main"
    subnet = "subnet-general"
  }
  mgmt = {
    sub_id         = "<enterSubID>"
    acr_rg         = "rg-cc-mgmt-shared"
    acr_name       = "acrcorpomgmtshared"
    private_dns_rg = "rg-cc-mgmt-network"
  }
}

resource = {
  storage = {
    type = "LRS"
    tier = "Standard"
    containers = [
      "images",
      "articles",
      "site"
    ]
  }
  sql = {
    adminUPN = "<enterUPN>"
    database = {
      sku         = "Basic"
      max_size_gb = 1
    }
  }
  container = {
    subnet_address = "10.51.2.0/27"
    app = {
      cpu          = 0.25
      memory       = "0.5Gi"
      min_replicas = 0
      max_replicas = 3
      image_tag    = "1.0.0"
      port         = 50505
    }
  }
}