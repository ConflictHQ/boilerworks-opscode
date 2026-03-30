# -----------------------------------------------------------------------------
# Azure Database for PostgreSQL Flexible Server (dev)
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${local.name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.tags, {
    Name = "${local.name}-postgres-dns"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${local.name}-postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = local.tags
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "${local.name}-db"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  version    = "16"
  sku_name   = var.postgres_sku
  storage_mb = 32768

  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  administrator_login    = "boilerworks"
  administrator_password = random_password.db_password.result

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  zone = "1"

  tags = merge(local.tags, {
    Name   = "${local.name}-db"
    Engine = "postgres-16"
  })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "boilerworks"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_disconnections" {
  name      = "log_disconnections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_lock_waits" {
  name      = "log_lock_waits"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "random_password" "db_password" {
  length  = 32
  special = false
}
