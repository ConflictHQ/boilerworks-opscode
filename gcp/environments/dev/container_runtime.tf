# -----------------------------------------------------------------------------
# Container Runtime Loader
#
# Enables Cloud Run, GKE, or both. Set via variables:
#   enable_cloud_run = true   (default)
#   enable_gke       = false  (default)
#
# Each runtime brings its own load balancer, IAM service accounts, DNS records,
# and health checks. Shared infrastructure (VPC, Cloud SQL, Memorystore,
# Cloud Storage, Secret Manager, Cloud DNS zone) lives in the environment root.
# -----------------------------------------------------------------------------

module "cloud_run" {
  count  = var.enable_cloud_run ? 1 : 0
  source = "./cloud-run"

  name               = local.name
  env                = local.env
  region             = local.region
  project_id         = local.project_id
  labels             = local.labels
  domain             = local.domain
  network_id         = google_compute_network.vpc.id
  subnet_id          = google_compute_subnetwork.private.id
  dns_zone_name      = google_dns_managed_zone.main.name
  container_image    = var.container_image
  db_connection_name = google_sql_database_instance.postgres.connection_name
  db_secret_id       = google_secret_manager_secret.db_credentials.secret_id
  app_secret_id      = google_secret_manager_secret.app_secrets.secret_id
  storage_bucket     = google_storage_bucket.files.name
}

module "gke" {
  count  = var.enable_gke ? 1 : 0
  source = "./gke"

  name       = local.name
  env        = local.env
  region     = local.region
  project_id = local.project_id
  labels     = local.labels
  network_id = google_compute_network.vpc.id
  subnet_id  = google_compute_subnetwork.private.id
}
