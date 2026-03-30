# -----------------------------------------------------------------------------
# Storage Account + Blob Container (S3 equivalent)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "files" {
  name                     = replace("${local.name}files", "-", "")
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "PUT", "POST"]
      allowed_origins    = ["https://${local.domain}", "https://*.${local.domain}"]
      exposed_headers    = ["ETag"]
      max_age_in_seconds = 3600
    }

    delete_retention_policy {
      days = 7
    }
  }

  tags = merge(local.tags, {
    Name    = "${local.name}-files"
    Purpose = "Application file storage"
  })
}

resource "azurerm_storage_container" "files" {
  name                  = "files"
  storage_account_name  = azurerm_storage_account.files.name
  container_access_type = "private"
}
