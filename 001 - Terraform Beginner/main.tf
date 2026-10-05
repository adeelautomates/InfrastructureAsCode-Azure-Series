/*
  ProjectName : Beginners Terraform
  Author : Adeel Anwar 
*/

# --- Providers --- #
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.76.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = "0acab36a-a5b3-489d-9a1d-420bd779cdcc"
}

# --- Variables --- #
variable "env" {
  description = "Set Environment"
}

variable "subscription_id" {
  description = "Set subscription to deploy to(via ID)"
  default     = "e95c588b-f194-4367-85e4-735e540151a2"
}

variable "region" {
  description = "Set Region"
  validation {
    condition = contains(
      [
        "canadacentral",
        "canadaeast"
      ],
      replace(lower(var.region), " ", "")
    )
    error_message = "Set region to canada central or canada east"
  }
}

# --- Locals --- #
locals {
  common_tags = {
    owner1       = "aanwar@lb4s.onmicrosoft.com"
    owner2       = "LeeG@lb4s.onmicrosoft.com"
    cost-centre  = "1001"
    creationTime = "2026-06-10 18:05"
    creator      = "aanwar@lb4s.onmicrosoft.com"
    creatorType  = "User"
    region       = var.region
  }
  network_address = ["10.0.0.0/16", "10.1.0.0/16"]
}
locals {
  region_short = replace(lower(var.region), " ", "") == "canadacentral" ? "cc" : "ce"
}

# --- Resources --- #
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.env}-${local.region_short}-tf"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env}-${local.region_short}-tf-001"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = local.network_address
  tags                = local.common_tags
}

resource "azurerm_subnet" "sn" {
  name                 = "subnet-general"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.env}-${local.region_short}-tf-001"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.common_tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "win-${var.env}-${local.region_short}-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  size                = "Standard_D2as_v6"
  admin_username      = "corpoadmin"
  admin_password      = data.azurerm_key_vault_secret.secret.value
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 140
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter-g2"
    version   = "latest"
  }
  tags = local.common_tags
}

#--- Data Sources ---#
data "azurerm_key_vault" "kv" {
  name                = "corpo-mgmt-kv-001"
  resource_group_name = "rg-cc-mgmt-creds-001"
}

data "azurerm_key_vault_secret" "secret" {
  name         = "vm-local-admin-default-pass"
  key_vault_id = data.azurerm_key_vault.kv.id
}

#--- Output ---#
output "firstAddressSpace" {
  value = tolist(azurerm_virtual_network.vnet.address_space)[0]
}

output "vm_info" {
  value = {
    id                  = azurerm_windows_virtual_machine.vm.id
    name                = azurerm_windows_virtual_machine.vm.name
    location            = azurerm_windows_virtual_machine.vm.location
    resource_group_name = azurerm_windows_virtual_machine.vm.resource_group_name
    ip                  = azurerm_network_interface.nic.private_ip_address
  }
}

output "vm_password" {
  value = azurerm_windows_virtual_machine.vm.admin_password
  sensitive = true
}