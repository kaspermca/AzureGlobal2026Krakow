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

module "app_service" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=app_service/v1.0.0"

  app_service = {
    name                = "my-app-service"
    location            = "northeurope"
    resource_group_name = "rg-user2"

    service_plan = {
      name     = "my-app-service-plan"
      sku_name = "B1"
      os_type  = "Linux"
    }

    site_config = {
      always_on = true
    }

    app_settings = {
      ENVIRONMENT = "dev"
      APP_NAME    = "my-app"
    }

    identity = {
      type = "SystemAssigned"
    }
  }

  tags = {
    environment = "dev"
    project     = "global-azure-2026"
    owner       = "kasper"
  }
}
