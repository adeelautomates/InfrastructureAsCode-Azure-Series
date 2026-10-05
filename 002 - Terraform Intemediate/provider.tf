terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.75"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.sub_id
}

provider "azurerm" {
  features {}
  alias           = "mgmt_sub"
  subscription_id = "<enterID>"
}