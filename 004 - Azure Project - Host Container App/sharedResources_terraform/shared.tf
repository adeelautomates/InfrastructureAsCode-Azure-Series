#--- Deploy Container Registry for our project
resource "azurerm_resource_group" "acr_rg" {
  provider = azurerm.mgmt
  name     = "rg-cc-mgmt-shared"
  location = "canada central"
}

resource "azurerm_container_registry" "acr" {
  provider = azurerm.mgmt
  name                = "acrcorpomgmtshared"
  resource_group_name = azurerm_resource_group.acr_rg.name
  location            = azurerm_resource_group.acr_rg.location

  sku           = "Basic"
  admin_enabled = false
}

data "azurerm_client_config" "current" {
  provider = azurerm.mgmt
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}