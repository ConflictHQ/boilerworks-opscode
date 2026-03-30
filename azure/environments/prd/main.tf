# -----------------------------------------------------------------------------
# Boilerworks — Azure Production Environment
#
# Planned services (not yet implemented):
#   - Azure Container Apps (compute — zone-redundant)
#   - Azure Database for PostgreSQL Flexible Server (HA, zone-redundant)
#   - Azure Cache for Redis (Premium tier, zone-redundant)
#   - Application Gateway v2 (zone-redundant)
#   - Azure DNS
#   - Azure Blob Storage (GRS)
#   - Azure Key Vault (soft-delete, purge protection)
#   - Azure Monitor + Log Analytics + Action Groups
#   - Azure Front Door (CDN + WAF)
#   - Virtual Network + Private Endpoints
#
# Production will mirror AWS prd patterns:
#   - Zone-redundant HA
#   - Higher resource limits
#   - Stricter RBAC
#   - Longer log retention
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # backend "azurerm" {
  #   resource_group_name  = "boilerworks-tfstate-rg"
  #   storage_account_name = "boilerworkstfstate"
  #   container_name       = "tfstate"
  #   key                  = "azure/prd/terraform.tfstate"
  # }
}
