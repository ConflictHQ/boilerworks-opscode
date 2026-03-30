# -----------------------------------------------------------------------------
# Secret Manager
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${local.name}-db-credentials"
  project   = local.project_id

  replication {
    auto {}
  }

  labels = merge(local.labels, {
    purpose = "database-authentication"
  })
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id

  secret_data = jsonencode({
    username = google_sql_user.boilerworks.name
    password = random_password.db_password.result
    host     = google_sql_database_instance.postgres.private_ip_address
    port     = 5432
    dbname   = google_sql_database.boilerworks.name
    instance = google_sql_database_instance.postgres.connection_name
    url      = "postgresql://${google_sql_user.boilerworks.name}:${random_password.db_password.result}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.boilerworks.name}"
  })
}

resource "google_secret_manager_secret" "app_secrets" {
  secret_id = "${local.name}-app-secrets"
  project   = local.project_id

  replication {
    auto {}
  }

  labels = merge(local.labels, {
    purpose = "application-configuration-secrets"
  })
}

resource "google_secret_manager_secret_version" "app_secrets" {
  secret = google_secret_manager_secret.app_secrets.id

  secret_data = jsonencode({
    SESSION_SECRET = random_password.session_secret.result
  })
}

resource "random_password" "session_secret" {
  length  = 64
  special = false
}
