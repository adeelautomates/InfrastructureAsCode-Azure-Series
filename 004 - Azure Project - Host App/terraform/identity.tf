resource "azurerm_user_assigned_identity" "app" {
  name                = "id-app-${var.config.main.env}-${var.config.main.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "storage_read" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azuread_app_role_assignment" "sql_graph_permissions" {
  for_each = toset([
    "User.Read.All",
    "GroupMember.Read.All",
    "Application.Read.All"
  ])
  app_role_id         = data.azuread_service_principal.microsoft_graph.app_role_ids[each.value]
  principal_object_id = azurerm_mssql_server.sql.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id
}

