# -----------------------------------------------------------------------------
# Log Analytics + Monitoring (CloudWatch equivalent)
#
# Compute-specific diagnostics live in container-apps/ and aks/ submodules.
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(local.tags, {
    Name    = "${local.name}-logs"
    Purpose = "Centralized logging and monitoring"
  })
}

# Action group placeholder — configure email/webhook/PagerDuty targets
resource "azurerm_monitor_action_group" "alerts" {
  name                = "${local.name}-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "bw-alerts"

  # Uncomment and configure when ready:
  # email_receiver {
  #   name          = "ops-team"
  #   email_address = "ops@boilerworks.net"
  # }

  tags = merge(local.tags, {
    Name = "${local.name}-alerts"
  })
}
