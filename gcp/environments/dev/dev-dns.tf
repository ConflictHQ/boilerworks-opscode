# -----------------------------------------------------------------------------
# Cloud DNS — Managed Zone (shared)
#
# DNS records pointing to load balancers are created by cloud-run/ and gke/
# submodules.
# -----------------------------------------------------------------------------

resource "google_dns_managed_zone" "main" {
  name        = "${local.name}-zone"
  dns_name    = "${local.domain}."
  description = "DNS zone for ${local.domain}"
  project     = local.project_id

  labels = local.labels
}
