terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0.0"
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


############################
# MANAGED IDENTITY
############################
module "managed_identity" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=managed_identity/v1.0.0"

  managed_identity = {
    name                = "${local.name_prefix}-mi"
    location            = local.location
    resource_group_name = local.resource_group_name
  }

  tags = {
    project = "global-azure-2026"
  }
}

############################
# KEY VAULT
############################
module "key_vault" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=key_vault/v1.0.0"

  key_vault = {
    name                = "${local.name_prefix}-kv"
    location            = local.location
    resource_group_name = local.resource_group_name
    tenant_id           = data.azurerm_client_config.current.tenant_id

    access_policies = [
      {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = module.managed_identity.principal_id

        secret_permissions = ["Get", "List", "Set"]
      }
    ]
  }

  tags = {
    project = "global-azure-2026"
  }
}

data "azurerm_client_config" "current" {}

############################
# AZURE CONTAINER REGISTRY
############################
module "acr" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=container_registry/v1.0.0"

  container_registry = {
    name                = "${local.name_prefix}acr"
    location            = local.location
    resource_group_name = local.resource_group_name
    sku                 = "Basic"
    admin_enabled       = true
  }

  tags = {
    project = "global-azure-2026"
  }
}

############################
# APPLICATION INSIGHTS
############################
module "app_insights" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=application_insights/v1.0.0"

  application_insights = {
    name                = "${local.name_prefix}-appi"
    location            = local.location
    resource_group_name = local.resource_group_name
    application_type    = "web"
  }

  tags = {
    project = "global-azure-2026"
  }
}

############################
# MS SQL
############################
module "mssql" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=mssql/v1.0.0"

  mssql = {
    name                = "${local.name_prefix}-sql"
    location            = local.location
    resource_group_name = local.resource_group_name

    administrator_login          = "sqladminuser"
    administrator_login_password = "P@ssw0rd1234!"

    database_name = "appdb"
    sku_name      = "Basic"
  }

  tags = {
    project = "global-azure-2026"
  }
}

############################
# APP SERVICE + PLAN (B1)
############################
module "app_service" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=app_service/v1.0.0"

  app_service = {
    name                = "${local.name_prefix}-app"
    location            = local.location
    resource_group_name = local.resource_group_name

    service_plan = {
      name     = "${local.name_prefix}-plan"
      sku_name = "B1"
      os_type  = "Linux"
    }

    identity = {
      type = "SystemAssigned"
    }

    app_settings = {
      APPINSIGHTS_INSTRUMENTATIONKEY = module.app_insights.instrumentation_key
      DOCKER_REGISTRY_SERVER_URL     = module.acr.login_server
      ENVIRONMENT                    = "dev"
    }
  }

  tags = {
    project = "global-azure-2026"
  }
}
