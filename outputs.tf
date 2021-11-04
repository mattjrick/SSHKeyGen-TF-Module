output "default_hostname" {
    description = "Hostname of the function app"
    value = azurerm_function_app.example.default_hostname
}

output "default_function_key" {
    description = "Default function key to access function app"
    value = data.azurerm_function_app_host_keys.example.default_function_key
    sensitive = true
}