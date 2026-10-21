terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id     = var.config.main.sub_id
  storage_use_azuread = true
  features {}
}

provider "azurerm" {
  alias           = "mgmt"
  subscription_id = var.config.mgmt.sub_id
  features {}
}

provider "azuread" {}