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

  # === Podstawowe ===
  name                = "my-app-service"
  location            = "northeurope"
  resource_group_name = "rg-user2"

  # === App Service Plan ===
  app_service_plan_name = "my-app-plan"
  sku_name              = "B1"
  os_type               = "Linux"

  # === Web App ===
  app_settings = {
    ENVIRONMENT = "dev"
    APP_NAME    = "my-app"
  }

  # === Container (jeśli linux + container) ===
  docker_image_name   = "myapp"
  docker_image_tag    = "latest"
  container_registry  = "gaacruser2.azurecr.io"

  # === Managed Identity ===
  enable_managed_identity = true

  # === Networking / security (jeśli wymagane w module) ===
  https_only = true

  tags = {
    environment = "dev"
    owner       = "kasper"
    project     = "global-azure"
  }
}
