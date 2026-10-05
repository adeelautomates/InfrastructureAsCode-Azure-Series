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

#--- Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.region_short}-${var.config.main.env}-${var.config.main.project_name}"
  location = var.config.main.region
  tags     = local.common_tags
  lifecycle {
    ignore_changes = [tags["creationTime"]]
  }
}

#--- Storage
module "sa" {
  source                          = "../../modules/storage"
  name                            = "stcp${var.config.main.env}${var.config.main.project_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.config.main.region
  account_replication_type        = var.storage.type
  containers                      = var.storage.containers
  grant_deployer_blob_contributor = true
  tags                            = local.common_tags
}

module "storage_blob_pe" {
  source = "../../modules/private_endpoints"
  name                = "pe-${module.sa.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.subnet.id
  private_service_connection_name = "psc-${module.sa.name}-blob"
  private_connection_resource_id  = module.sa.id
  subresource_names               = ["blob"]
  private_dns_zone_ids = [
    data.azurerm_private_dns_zone.storage_blob.id
  ]
  tags = local.common_tags
}


# #--- Virtual Machine
module "vm" {
  source = "../../modules/linux_virtual_machine"
  name                = local.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.subnet.id
  size           = var.virtual_machine.size
  zone           = var.virtual_machine.zone
  admin_username = var.virtual_machine.username
  admin_password = module.vm_password.value
  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config

    package_update: true

    packages:
      - curl

    runcmd:
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  CLOUD_INIT
  )
  os_disk_name                 = "disk-${local.vm_name}-os"
  os_disk_caching              = var.virtual_machine.os_disk.caching
  os_disk_storage_account_type = var.virtual_machine.os_disk.storage_account_type
  os_disk_size_gb              = var.virtual_machine.os_disk.disk_size_gb
  image_publisher = var.virtual_machine.image.publisher
  image_offer     = var.virtual_machine.image.offer
  image_sku       = var.virtual_machine.image.sku
  image_version   = var.virtual_machine.image.version
  tags = local.common_tags
}

#--- Key Vault
module "vm_password" {
  source = "../../modules/keyvault_secret"
  providers = {
    azurerm = azurerm.mgmt
  }
  name         = "password-${local.vm_name}"
  key_vault_id = data.azurerm_key_vault.kv.id
  password_length = 20
}


# #--- RBAC Connectivity Between Services
resource "azurerm_role_assignment" "vm_rg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = module.vm.principal_id
}
resource "azurerm_role_assignment" "vm_storage_blob_reader" {
  scope                = module.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.vm.principal_id
}

#--- RBAC Grant Owners Access
resource "azurerm_role_assignment" "rg" {
  for_each             = data.azuread_user.entra_owners
  scope                = azurerm_resource_group.rg.id
  role_definition_name = var.owner_rbac.rg
  principal_id         = each.value.object_id
}

resource "azurerm_role_assignment" "storage" {
  for_each             = data.azuread_user.entra_owners
  scope                = module.sa.id
  role_definition_name = var.owner_rbac.storage_account
  principal_id         = each.value.object_id
}