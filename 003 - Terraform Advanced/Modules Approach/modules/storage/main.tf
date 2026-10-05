resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_kind                    = var.account_kind
  account_replication_type        = var.account_replication_type
  default_to_oauth_authentication = var.default_to_oauth_authentication
  shared_access_key_enabled       = var.shared_access_key_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  public_network_access_enabled   = var.public_network_access_enabled
  tags                            = var.tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_storage_container" "this" {
  for_each              = var.containers
  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.access
  depends_on            = [azurerm_role_assignment.this]
}

data "azurerm_client_config" "current" {}

# #--- RBAC Grant Permission to interact with data plane for SA
resource "azurerm_role_assignment" "this" {
  count                = var.grant_deployer_blob_contributor ? 1 : 0
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}