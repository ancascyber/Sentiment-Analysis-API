output "function_app_hostname" {
  value = azurerm_linux_function_app.func.default_hostname
}

output "apim_gateway_url" {
  value = azurerm_api_management.apim.gateway_url
}

output "language_endpoint" {
  value = azurerm_cognitive_account.language.endpoint
}
