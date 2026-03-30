# -----------------------------------------------------------------------------
# Boilerworks — Azure Terraform State Backend
#
# Creates a Storage Account + container for Terraform remote state.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  description = "Resource group for the state backend"
  type        = string
  default     = "boilerworks-tfstate-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westus2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "boilerworks"
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Service   = var.project_name
    ManagedBy = "terraform"
    Purpose   = "Terraform state backend"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "${replace(var.project_name, "-", "")}tfstate"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Service   = var.project_name
    ManagedBy = "terraform"
    Purpose   = "Terraform state storage"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

output "storage_account_name" {
  description = "Storage account name for Terraform state"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Blob container name for Terraform state"
  value       = azurerm_storage_container.tfstate.name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.tfstate.name
}
