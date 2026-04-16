terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.1.0"
    }
  }
}
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-user2"
    storage_account_name = "gastorageuser2"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

module "keyvault" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=keyvault/v1.0.0"
  keyvault_name = "gakvuser2-2026"
  resource_group = {
    location = "northeurope"
    name     = "rg-user2"
  }
  network_acls = {
    default_action = "Deny"
    bypass = "AzureServices"
  }

}
