terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_cognitive_account" "language" {
  name                = "${var.prefix}-language"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "TextAnalytics"
  sku_name            = "F0"
}

resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "func" {
  name                       = "${var.prefix}-func"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  https_only                 = true

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "LANGUAGE_ENDPOINT"        = azurerm_cognitive_account.language.endpoint
    "LANGUAGE_KEY"             = azurerm_cognitive_account.language.primary_access_key
  }
}

resource "azurerm_api_management" "apim" {
  name                = "${var.prefix}-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "your-name"
  publisher_email     = "your-email@example.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "sentiment_api" {
  name                = "sentiment-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Sentiment API"
  path                = "sentiment"
  protocols           = ["https"]
  service_url         = "https://${azurerm_linux_function_app.func.default_hostname}/api"
}

resource "azurerm_api_management_api_policy" "policy" {
  api_name            = azurerm_api_management_api.sentiment_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = file("apim_policy.xml")
}

resource "azurerm_api_management_product" "free_tier" {
  product_id            = "free-tier"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Free Tier"
  subscription_required = false
  published             = true
}

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "sentiment-api-budget"
  resource_group_id = azurerm_resource_group.rg.id
  amount            = 10
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = ["ancascyber@gmail.com"]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = ["ancascyber@gmail.com"]
  }
}






