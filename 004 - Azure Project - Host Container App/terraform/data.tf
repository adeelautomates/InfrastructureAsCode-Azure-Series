data "azurerm_container_registry" "acr" {
  provider            = azurerm.mgmt
  name                = var.config.mgmt.acr_name
  resource_group_name = var.config.mgmt.acr_rg
}

data "azurerm_resource_group" "net_rg" {
  name = var.config.network.rg
}

data "azurerm_virtual_network" "vnet" {
  name                = var.config.network.vnet
  resource_group_name = data.azurerm_resource_group.net_rg.name
}

data "azurerm_subnet" "general" {
  name                 = var.config.network.subnet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.net_rg.name
}

data "azurerm_private_dns_zone" "blob" {
  provider            = azurerm.mgmt
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.config.mgmt.private_dns_rg
}

data "azurerm_private_dns_zone" "sql" {
  provider            = azurerm.mgmt
  name                = "privatelink.database.windows.net"
  resource_group_name = var.config.mgmt.private_dns_rg
}

# Collect your public IP to whitelist it for resources that are otherwise being reached through private endpoints only
data "http" "public_ip" {
  url = "https://api.ipify.org"
}

data "azuread_user" "sql_admin" {
  user_principal_name = var.resource.sql.adminUPN
}

data "azuread_service_principal" "microsoft_graph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}