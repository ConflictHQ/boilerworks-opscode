# -----------------------------------------------------------------------------
# Boilerworks — GCP Production Environment
#
# Planned services (not yet implemented):
#   - Cloud Run (compute — multi-region)
#   - Cloud SQL for PostgreSQL (HA, regional)
#   - Memorystore for Redis (HA, standard tier)
#   - Cloud Load Balancing (global)
#   - Cloud DNS
#   - Cloud Storage (multi-region)
#   - Secret Manager
#   - Cloud Logging + Cloud Monitoring + Alerting
#   - Cloud Armor (WAF)
#   - VPC + Private Service Connect
#
# Production will mirror AWS prd patterns:
#   - Multi-zone/region HA
#   - Higher resource limits
#   - Stricter IAM
#   - Longer log retention
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # backend "gcs" {
  #   bucket = "tf-state-boilerworks"
  #   prefix = "gcp/prd"
  # }
}
