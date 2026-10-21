terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
provider "azurerm" {
  alias           = "prod"
  subscription_id = "<enterSubID>"
  features {}
}
provider "azurerm" {
  alias           = "dev"
  subscription_id = "<enterSubID>"
  features {}
}
provider "azurerm" {
  alias           = "mgmt"
  subscription_id = "<enterSubID>"
  features {}
}