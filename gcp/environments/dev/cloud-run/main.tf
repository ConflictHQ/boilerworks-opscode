# -----------------------------------------------------------------------------
# Cloud Run Container Runtime
#
# Cloud Run service, HTTPS Load Balancer (managed SSL), serverless NEG,
# URL map, health check, DNS records, IAM service account.
# Called by container_runtime.tf when enable_cloud_run = true.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# IAM — Cloud Run Service Account
# =============================================================================

resource "google_service_account" "cloud_run" {
  account_id   = "${var.name}-run-sa"
  display_name = "Cloud Run service account for ${var.name}"
  project      = var.project_id
}

resource "google_project_iam_member" "cloud_run_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_project_iam_member" "cloud_run_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_project_iam_member" "cloud_run_storage" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_project_iam_member" "cloud_run_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# =============================================================================
# Cloud Run Service
# =============================================================================

resource "google_cloud_run_v2_service" "app" {
  name     = "${var.name}-app"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.cloud_run.email

    scaling {
      min_instance_count = 0
      max_instance_count = 4
    }

    containers {
      image = var.container_image

      ports {
        container_port = 8000
      }

      env {
        name  = "ENVIRONMENT"
        value = var.env
      }

      env {
        name  = "GCP_REGION"
        value = var.region
      }

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = var.db_secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "APP_SECRETS"
        value_source {
          secret_key_ref {
            secret  = var.app_secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      startup_probe {
        http_get {
          path = "/health/"
          port = 8000
        }
        initial_delay_seconds = 10
        period_seconds        = 3
        failure_threshold     = 10
      }

      liveness_probe {
        http_get {
          path = "/health/"
          port = 8000
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    labels = var.labels
  }

  labels = var.labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# Allow unauthenticated access (public-facing service behind LB)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# =============================================================================
# Serverless VPC Access Connector (Cloud Run -> VPC)
# =============================================================================

resource "google_vpc_access_connector" "connector" {
  name          = "${var.name}-connector"
  region        = var.region
  project       = var.project_id
  network       = var.network_id
  ip_cidr_range = "10.0.100.0/28"

  min_instances = 2
  max_instances = 3
}

# =============================================================================
# HTTPS Load Balancer
# =============================================================================

resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.name}-run-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project_id

  cloud_run {
    service = google_cloud_run_v2_service.app.name
  }
}

resource "google_compute_backend_service" "cloud_run" {
  name    = "${var.name}-run-backend"
  project = var.project_id

  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "default" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.cloud_run.id
  project         = var.project_id
}

resource "google_compute_managed_ssl_certificate" "default" {
  name    = "${var.name}-ssl-cert"
  project = var.project_id

  managed {
    domains = [var.domain, "*.${var.domain}"]
  }
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
  project          = var.project_id
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name}-https-rule"
  target                = google_compute_target_https_proxy.default.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  project               = var.project_id

  labels = var.labels
}

# HTTP -> HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name    = "${var.name}-http-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "${var.name}-http-redirect-proxy"
  url_map = google_compute_url_map.http_redirect.id
  project = var.project_id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name                  = "${var.name}-http-redirect-rule"
  target                = google_compute_target_http_proxy.http_redirect.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  project               = var.project_id

  labels = var.labels
}

# =============================================================================
# DNS Records
# =============================================================================

resource "google_dns_record_set" "app" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  project      = var.project_id

  rrdatas = [google_compute_global_forwarding_rule.https.ip_address]
}

resource "google_dns_record_set" "wildcard" {
  name         = "*.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  project      = var.project_id

  rrdatas = [google_compute_global_forwarding_rule.https.ip_address]
}
