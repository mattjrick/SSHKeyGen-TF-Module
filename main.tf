resource "azurerm_resource_group" "example" {
  name     = var.name
  location = var.location
}

data "azurerm_client_config" "current" {
}

resource "random_string" "vault_key" {
  length           = 16
  special          = true
  number           = false
  override_special = "-"
}

resource "azurerm_storage_account" "example" {
  name                     = azurerm_resource_group.example.name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_app_service_plan" "example" {
  name                = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "example" {
  name                   = "latest-build.zip"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  source                 = "../../Functions/published/latest-build.zip"
}

resource "azurerm_function_app" "example" {
  name                       = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_id        = azurerm_app_service_plan.example.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  os_type                    = "linux"
  version                    = "~3"
  identity {
    type = "SystemAssigned"
      } 
  site_config {
    linux_fx_version = "PYTHON|3.9"
  }
  app_settings = {
    "KEY_VAULT" = random_string.vault_key.result,
    "WEBSITE_RUN_FROM_PACKAGE" = azurerm_storage_blob.example.url,
    "FUNCTIONS_WORKER_RUNTIME" = "python"
  }
}

resource "azurerm_key_vault" "example" {
  name                        = random_string.vault_key.result
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = azurerm_function_app.example.identity.0.tenant_id
    object_id = azurerm_function_app.example.identity.0.principal_id

    secret_permissions = [
      "set", "list", "get"
    ]
  }
}

data "azurerm_function_app_host_keys" "example" {
  name = azurerm_function_app.example.name
  resource_group_name = azurerm_resource_group.example.name
}
