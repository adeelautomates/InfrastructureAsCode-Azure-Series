locals {
  location = "Canada Central"
  private_dns_zones = toset([
    "privatelink.blob.core.windows.net",
    "privatelink.database.windows.net"
  ])
}

# Production
resource "azurerm_resource_group" "prod_network" {
  provider = azurerm.prod
  name     = "rg-cc-prod-network"
  location = local.location
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_virtual_network" "prod_main" {
  provider = azurerm.prod
  name                = "vnet-corpo-prod-main"
  location            = azurerm_resource_group.prod_network.location
  resource_group_name = azurerm_resource_group.prod_network.name
  address_space       = ["10.50.0.0/16"]
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_subnet" "prod_general" {
  provider = azurerm.prod
  name                 = "subnet-general"
  resource_group_name  = azurerm_resource_group.prod_network.name
  virtual_network_name = azurerm_virtual_network.prod_main.name
  address_prefixes     = ["10.50.1.0/24"]
}

# Development
resource "azurerm_resource_group" "dev_network" {
  provider = azurerm.dev
  name     = "rg-cc-dev-network"
  location = local.location
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_virtual_network" "dev_main" {
  provider = azurerm.dev
  name                = "vnet-corpo-dev-main"
  location            = azurerm_resource_group.dev_network.location
  resource_group_name = azurerm_resource_group.dev_network.name
  address_space       = ["10.51.0.0/16"]
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_subnet" "dev_general" {
  provider = azurerm.dev
  name                 = "subnet-general"
  resource_group_name  = azurerm_resource_group.dev_network.name
  virtual_network_name = azurerm_virtual_network.dev_main.name
  address_prefixes     = ["10.51.1.0/24"]
}

# Management
resource "azurerm_resource_group" "mgmt_network" {
  provider = azurerm.mgmt
  name     = "rg-cc-mgmt-network"
  location = local.location
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_virtual_network" "mgmt_main" {
  provider = azurerm.mgmt
  name                = "vnet-corpo-mgmt-main"
  location            = azurerm_resource_group.mgmt_network.location
  resource_group_name = azurerm_resource_group.mgmt_network.name
  address_space       = ["10.52.0.0/16"]
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_subnet" "mgmt_general" {
  provider = azurerm.mgmt
  name                 = "subnet-general"
  resource_group_name  = azurerm_resource_group.mgmt_network.name
  virtual_network_name = azurerm_virtual_network.mgmt_main.name
  address_prefixes     = ["10.52.1.0/24"]
}

# Private DNS zones (live in the management subscription)
resource "azurerm_private_dns_zone" "dns" {
  provider = azurerm.mgmt
  for_each = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.mgmt_network.name
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "mgmt" {
  provider = azurerm.mgmt
  for_each = azurerm_private_dns_zone.dns
  name                  = "link-mgmt"
  resource_group_name   = azurerm_resource_group.mgmt_network.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.mgmt_main.id
  registration_enabled  = false
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "dev" {
  provider = azurerm.mgmt
  for_each = azurerm_private_dns_zone.dns
  name                  = "link-dev"
  resource_group_name   = azurerm_resource_group.mgmt_network.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.dev_main.id
  registration_enabled  = false
  lifecycle {
    ignore_changes = [ tags ]
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "prod" {
  provider = azurerm.mgmt
  for_each = azurerm_private_dns_zone.dns
  name                  = "link-prod"
  resource_group_name   = azurerm_resource_group.mgmt_network.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.prod_main.id
  registration_enabled  = false
  lifecycle {
    ignore_changes = [ tags ]
  }
}