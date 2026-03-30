# -----------------------------------------------------------------------------
# Boilerworks — Azure Development Environment
#
# Planned services (not yet implemented):
#   - Azure Container Apps (compute — ECS Fargate equivalent)
#   - Azure Database for PostgreSQL Flexible Server (database)
#   - Azure Cache for Redis (cache)
#   - Application Gateway (ALB equivalent)
#   - Azure DNS (Route53 equivalent)
#   - Azure Blob Storage (S3 equivalent)
#   - Azure Key Vault (Secrets Manager equivalent)
#   - Azure Monitor + Log Analytics (CloudWatch equivalent)
#   - Azure Front Door (CDN + WAF)
#   - Virtual Network + Private Endpoints
#
# This file will be populated when Azure support is implemented.
# Follow the same patterns as the AWS implementation:
#   - Environment separation (dev/prd)
#   - Reusable modules
#   - Tagged resources
#   - Least-privilege RBAC
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # backend "azurerm" {
  #   resource_group_name  = "boilerworks-tfstate-rg"
  #   storage_account_name = "boilerworkstfstate"
  #   container_name       = "tfstate"
  #   key                  = "azure/dev/terraform.tfstate"
  # }
}
