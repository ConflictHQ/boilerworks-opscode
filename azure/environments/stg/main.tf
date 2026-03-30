# -----------------------------------------------------------------------------
# Boilerworks — Azure Staging Environment
#
# Staging mirrors production topology at reduced scale.
# See dev/main.tf for planned services list.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # backend "azurerm" {
  #   resource_group_name  = "boilerworks-tfstate-rg"
  #   storage_account_name = "boilerworkstfstate"
  #   container_name       = "tfstate"
  #   key                  = "azure/stg/terraform.tfstate"
  # }
}
