# -----------------------------------------------------------------------------
# Cloud Monitoring — Shared (notification channel placeholder)
#
# Compute-specific log-based metrics and alerting policies live in
# cloud-run/ and gke/ submodules.
# -----------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  display_name = "${local.name}-alerts"
  type         = "email"
  project      = local.project_id

  labels = {
    email_address = "alerts@${local.domain}"
  }

  user_labels = local.labels
}
