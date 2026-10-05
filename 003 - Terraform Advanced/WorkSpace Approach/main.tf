locals {
  region_short = var.config.main.region_short
  common_tags = {
    owner1       = var.config.tags.owner1
    owner2       = var.config.tags.owner2
    cost-centre  = var.config.tags.costcentre
    projectName  = var.config.main.project_name
    managedBy    = "Terraform"
    creationTime = formatdate("YYYY-MM-DD hh:mm", timestamp())
  }
  vm_name = "vm-linux-${var.config.main.env}-${var.config.main.project_name}"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.region_short}-${var.config.main.env}-${var.config.main.project_name}"
  location = var.config.main.region
  tags     = local.common_tags
  lifecycle {
    ignore_changes = [tags["creationTime"]]
  }
}

#--- Storage
resource "azurerm_storage_account" "sa" {
  name                            = "stcp${var.config.main.env}${var.config.main.project_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.config.main.region
  account_tier                    = var.storage.tier
  account_kind                    = var.storage.kind
  account_replication_type        = var.storage.type
  default_to_oauth_authentication = var.storage.default_oauth
  shared_access_key_enabled       = var.storage.shared_key_access
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = true
  tags                            = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azapi_update_resource" "storage_settings" {
  type = "Microsoft.Storage/storageAccounts@2026-04-01"
  resource_id = azurerm_storage_account.sa.id
  body = {
    properties = {
      azureFilesIdentityBasedAuthentication = {
        smbOAuthSettings = {
          isSmbOAuthEnabled = true
        }
      }
    }
  }
}



resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-${azurerm_storage_account.sa.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.subnet.id
  private_service_connection {
    name                           = "psc-${azurerm_storage_account.sa.name}-blob"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.storage_blob.id
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
  for_each              = var.storage.containers
  name                  = each.key
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = each.value.access
  depends_on            = [azurerm_role_assignment.sa_blob_contributor]
}

#--- Key Vault
resource "random_password" "vm_password" {
  length           = 16
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$*"
}

resource "azurerm_key_vault_secret" "vm_password" {
  provider     = azurerm.mgmt
  name         = "password-${local.vm_name}"
  value        = random_password.vm_password.result
  key_vault_id = data.azurerm_key_vault.kv.id
}

#--- Virtual Machine Creation
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = local.vm_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.virtual_machine.size
  zone                            = var.virtual_machine.zone
  admin_username                  = var.virtual_machine.username
  admin_password                  = azurerm_key_vault_secret.vm_password.value
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]
  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config

    package_update: true

    packages:
      - curl

    runcmd:
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  CLOUD_INIT
  )
  os_disk {
    name                 = "disk-${local.vm_name}-os"
    caching              = var.virtual_machine.os_disk.caching
    storage_account_type = var.virtual_machine.os_disk.storage_account_type
    disk_size_gb         = var.virtual_machine.os_disk.disk_size_gb
  }
  source_image_reference {
    publisher = var.virtual_machine.image.publisher
    offer     = var.virtual_machine.image.offer
    sku       = var.virtual_machine.image.sku
    version   = var.virtual_machine.image.version
  }
  identity {
    type = "SystemAssigned"
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

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${local.vm_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
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

#--- RBAC Connectivity Between Services
resource "azurerm_role_assignment" "vm_storage_blob_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

resource "azurerm_role_assignment" "vm_rg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

#--- RBAC Grant Permission to interact with data plane for SA
resource "azurerm_role_assignment" "sa_blob_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

#--- RBAC Grant Owners Access
resource "azurerm_role_assignment" "rg" {
  for_each             = data.azuread_user.entra_owners
  scope                = azurerm_resource_group.rg.id
  role_definition_name = var.owner_rbac["rg"]
  principal_id         = each.value.object_id
}
resource "azurerm_role_assignment" "storage" {
  for_each             = data.azuread_user.entra_owners
  scope                = azurerm_storage_account.sa.id
  role_definition_name = var.owner_rbac["storage_account"]
  principal_id         = each.value.object_id
}