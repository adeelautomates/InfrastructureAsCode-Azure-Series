terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id     = var.config.main.sub_id
  storage_use_azuread = true
}

provider "azurerm" {
  alias = "mgmt"
  features {}
  subscription_id = var.config.mgmt.sub_id
}

provider "azuread" {}