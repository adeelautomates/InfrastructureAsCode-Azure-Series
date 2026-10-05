data "azuread_user" "entra_owners" {
  for_each = toset([
    var.config.tags.owner1,
    var.config.tags.owner2
  ])
  user_principal_name = each.value
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "vnet" {
  name                = var.config.network.vnet
  resource_group_name = var.config.network.rg
}

data "azurerm_subnet" "subnet" {
  name                 = var.config.network.subnet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = var.config.network.rg
}

data "azurerm_key_vault" "kv" {
  provider            = azurerm.mgmt
  name                = var.config.mgmt.kv_name
  resource_group_name = var.config.mgmt.kv_rg
}

data "azurerm_private_dns_zone" "storage_blob" {
  provider            = azurerm.mgmt
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.config.mgmt.private_dns_rg
}