# -----------------------------------------------------------------------------
# Container Runtime Loader
#
# Enables Container Apps, AKS, or both. Set via variables:
#   enable_container_apps = true   (default)
#   enable_aks            = false  (default)
#
# Each runtime brings its own ingress, managed identity, and DNS records.
# Shared infrastructure (VNet, PostgreSQL, Redis, Storage, Key Vault,
# DNS zone, Log Analytics) lives in the environment root.
# -----------------------------------------------------------------------------

module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0
  source = "./container-apps"

  name                       = local.name
  env                        = local.env
  location                   = local.location
  tags                       = local.tags
  resource_group_name        = azurerm_resource_group.main.name
  container_apps_subnet_id   = azurerm_subnet.container_apps.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  dns_zone_name              = azurerm_dns_zone.main.name
  domain                     = local.domain
  key_vault_id               = azurerm_key_vault.main.id
  storage_account_id         = azurerm_storage_account.files.id
  container_image            = var.container_image
  container_cpu              = var.container_cpu
  container_memory           = var.container_memory
}

module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "./aks"

  name                       = local.name
  env                        = local.env
  location                   = local.location
  tags                       = local.tags
  resource_group_name        = azurerm_resource_group.main.name
  vnet_id                    = azurerm_virtual_network.main.id
  aks_subnet_id              = azurerm_subnet.container_apps.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}
