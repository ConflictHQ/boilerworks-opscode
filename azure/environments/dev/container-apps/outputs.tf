output "fqdn" {
  description = "Container App default FQDN"
  value       = azurerm_container_app.app.ingress[0].fqdn
}

output "app_url" {
  description = "Container App HTTPS URL"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "environment_id" {
  description = "Container Apps Environment ID"
  value       = azurerm_container_app_environment.main.id
}

output "identity_principal_id" {
  description = "Managed identity principal ID for the app"
  value       = azurerm_user_assigned_identity.app.principal_id
}
