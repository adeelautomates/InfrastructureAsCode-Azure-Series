locals {
  common_tags = {
    owner1       = var.config.tags.owner1
    owner2       = var.config.tags.owner2
    cost-centre  = var.config.tags.costcentre
    projectName  = var.config.main.project_name
    managedBy    = "Terraform"
    creationTime = formatdate("YYYY-MM-DD hh:mm", timestamp())
  }
  private_endpoints = {
    sql = {
      resource_id = azurerm_mssql_server.sql.id
      subresource = "sqlServer"
      dns_zone_id = data.azurerm_private_dns_zone.sql.id
    }
    storage = {
      resource_id = azurerm_storage_account.storage.id
      subresource = "blob"
      dns_zone_id = data.azurerm_private_dns_zone.blob.id
    }
  }
}

#--- Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.config.main.region_short}-${var.config.main.env}-${var.config.main.project_name}"
  location = var.config.main.region
  tags     = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

#--- Storage Account
resource "azurerm_storage_account" "storage" {
  name                            = "sa${var.config.main.project_name}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = var.resource.storage.tier
  account_replication_type        = var.resource.storage.type
  public_network_access_enabled   = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  network_rules {
    default_action = "Deny"
    ip_rules = [
      trimspace(data.http.public_ip.response_body)
    ]
  }
  tags = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_storage_container" "containers" {
  for_each              = var.resource.storage.containers
  name                  = each.value
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}


#--- SQL
resource "azurerm_mssql_server" "sql" {
  name                          = "sql-${var.config.main.env}-${var.config.main.project_name}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  azuread_administrator {
    login_username              = data.azuread_user.sql_admin.user_principal_name
    object_id                   = data.azuread_user.sql_admin.object_id
    azuread_authentication_only = true
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_mssql_firewall_rule" "my_ip" {
  name             = "adeel-public-ip"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = trimspace(data.http.public_ip.response_body)
  end_ip_address   = trimspace(data.http.public_ip.response_body)
}

resource "azurerm_mssql_database" "db" {
  name        = "db-${var.config.main.env}-${var.config.main.project_name}"
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = var.resource.sql.database.sku
  max_size_gb = var.resource.sql.database.max_size_gb
  tags        = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

#--- Networking 
resource "azurerm_private_endpoint" "pe" {
  for_each            = local.private_endpoints
  name                = "pe-${each.key}-${var.config.main.env}-${var.config.main.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = data.azurerm_subnet.general.id
  private_service_connection {
    name                           = "pe-${each.key}-${var.config.main.env}-${var.config.main.project_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [each.value.dns_zone_id]
  }
  tags = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_subnet" "container_apps" {
  name                 = "subnet-containerapps-${var.config.main.project_name}"
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [var.resource.container.subnet_address]
  delegation {
    name = "container-apps"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.App/environments"
    }
  }
}

#--- Monitoring
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${var.config.main.env}-${var.config.main.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = "30"
  tags                = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}


#--- Container Apps
resource "azurerm_container_app_environment" "env" {
  name                       = "ca-env-${var.config.main.env}-${var.config.main.project_name}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}


resource "azurerm_container_app" "app" {
  name                         = "ca-app-${var.config.main.env}-${var.config.main.project_name}"
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  container_app_environment_id = azurerm_container_app_environment.env.id
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.app.id
  }

  template {
    min_replicas = var.resource.container.app.min_replicas
    max_replicas = var.resource.container.app.max_replicas
    container {
      name   = var.config.main.project_name
      image  = "${data.azurerm_container_registry.acr.login_server}/${var.config.main.project_name}:${var.resource.container.app.image_tag}"
      cpu    = var.resource.container.app.cpu
      memory = var.resource.container.app.memory

      env {
        name  = "STORAGE_ACCOUNT_URL"
        value = azurerm_storage_account.storage.primary_blob_endpoint
      }
      env {
        name  = "SQL_SERVER"
        value = azurerm_mssql_server.sql.fully_qualified_domain_name
      }
      env {
        name  = "SQL_DATABASE"
        value = azurerm_mssql_database.db.name
      }
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.app.client_id
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = var.resource.container.app.port
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = var.resource.container.app.port
      }
    }
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.resource.container.app.port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.common_tags
  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.storage_read
  ]
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}