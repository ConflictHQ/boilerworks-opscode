# -----------------------------------------------------------------------------
# Azure DNS — Hosted Zone (shared)
#
# DNS records pointing to Container Apps / AKS ingress are created by
# container-apps/ and aks/ submodules.
# -----------------------------------------------------------------------------

resource "azurerm_dns_zone" "main" {
  name                = local.domain
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.tags, {
    Name = local.domain
  })
}
