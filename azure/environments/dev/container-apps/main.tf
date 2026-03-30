# -----------------------------------------------------------------------------
# Azure Container Apps Runtime (ECS Fargate equivalent)
#
# Container Apps Environment, Container App with built-in HTTPS ingress,
# managed identity, Key Vault access, and DNS records.
# Called by container_runtime.tf when enable_container_apps = true.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# =============================================================================
# Managed Identity
# =============================================================================

resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.name}-app-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, { Name = "${var.name}-app-identity" })
}

# Grant the app identity access to Key Vault secrets
resource "azurerm_role_assignment" "app_kv_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Grant the app identity access to Storage
resource "azurerm_role_assignment" "app_storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# =============================================================================
# Container Apps Environment
# =============================================================================

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.name}-cae"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.container_apps_subnet_id

  tags = merge(var.tags, { Name = "${var.name}-cae" })
}

# =============================================================================
# Container App
# =============================================================================

resource "azurerm_container_app" "app" {
  name                         = "${var.name}-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  template {
    min_replicas = 1
    max_replicas = 4

    container {
      name   = "app"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "ENVIRONMENT"
        value = var.env
      }

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.app.client_id
      }

      liveness_probe {
        transport = "HTTP"
        port      = 8000
        path      = "/health/"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8000
        path      = "/health/"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-app" })

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}

# =============================================================================
# DNS Records
# =============================================================================

resource "azurerm_dns_cname_record" "app" {
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = azurerm_container_app.app.ingress[0].fqdn

  tags = var.tags
}

resource "azurerm_dns_cname_record" "wildcard" {
  name                = "*"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = azurerm_container_app.app.ingress[0].fqdn

  tags = var.tags
}

# =============================================================================
# Custom Domain Binding (optional — requires DNS validation)
# =============================================================================

# Uncomment when DNS zone is delegated and records are live:
# resource "azurerm_container_app_custom_domain" "app" {
#   name             = var.domain
#   container_app_id = azurerm_container_app.app.id
#
#   lifecycle {
#     ignore_changes = [certificate_binding_type]
#   }
# }
