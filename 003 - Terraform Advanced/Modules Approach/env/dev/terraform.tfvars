#--- Environment Config
config = {
  main = {
    sub_id       = "<sub ID>"
    env          = "dev"
    region       = "canadacentral"
    region_short = "cc"
    project_name = "clientportal"
  }
  tags = {
    costcentre = 1001
    owner1     = "<UPN>"
    owner2     = "<UPN>"
  }
  network = {
    rg     = "rg-cc-dev-network-001"
    vnet   = "corpo-dev-vnet-001"
    subnet = "subnet-general"
  }
  mgmt = {
    sub_id         = "<sub ID>"
    kv_rg          = "rg-cc-mgmt-creds-001"
    kv_name        = "corpo-mgmt-kv-001"
    private_dns_rg = "rg-cc-mgmt-network-001"
  }
}

virtual_machine = {
  size     = "Standard_B2s"
  zone     = "1"
  username = "azureadmin"
  image = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 127
  }
}

storage = {
  tier              = "Standard"
  kind              = "StorageV2"
  type              = "LRS"
  default_oauth     = true
  shared_key_access = false
  containers = {
    img = {
      access = "blob"
    }
    general = {
      access = "private"
    }
    logs = {
      access = "private"
    }
    temp = {
      access = "private"
    }
    test = {
      access = "private"
    }
  }
}

owner_rbac = {
  rg              = "Contributor"
  storage_account = "Storage Blob Data Contributor"
}