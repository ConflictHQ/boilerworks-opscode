# -----------------------------------------------------------------------------
# Memorystore Redis 7 (basic tier for dev)
# -----------------------------------------------------------------------------

resource "google_redis_instance" "redis" {
  name           = "${local.name}-redis"
  tier           = "BASIC" # Single node for dev
  memory_size_gb = var.redis_memory_size_gb
  region         = local.region
  project        = local.project_id

  redis_version = "REDIS_7_0"

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_configs = {
    maxmemory-policy = "volatile-lru"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "MONDAY"
      start_time {
        hours   = 6
        minutes = 0
      }
    }
  }

  labels = local.labels

  depends_on = [google_service_networking_connection.private_vpc]
}
