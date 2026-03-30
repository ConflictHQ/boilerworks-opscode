# -----------------------------------------------------------------------------
# Cloud Storage — File Storage Bucket
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "files" {
  name     = "${local.name}-files-${local.project_id}"
  location = local.region
  project  = local.project_id

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  cors {
    origin          = ["https://${local.domain}", "https://*.${local.domain}"]
    method          = ["GET", "PUT", "POST"]
    response_header = ["Content-Type", "ETag"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  labels = merge(local.labels, {
    purpose = "application-file-storage"
  })
}
