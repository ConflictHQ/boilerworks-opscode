# -----------------------------------------------------------------------------
# Secrets Manager (production)
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name}-db-credentials"
  description = "Database credentials for ${local.name}"

  tags = merge(local.tags, {
    Name    = "${local.name}-db-credentials"
    Purpose = "Database authentication"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_rds_cluster.aurora.master_username
    password = random_password.db_password.result
    host     = aws_rds_cluster.aurora.endpoint
    port     = aws_rds_cluster.aurora.port
    dbname   = aws_rds_cluster.aurora.database_name
    url      = "postgresql://${aws_rds_cluster.aurora.master_username}:${random_password.db_password.result}@${aws_rds_cluster.aurora.endpoint}:${aws_rds_cluster.aurora.port}/${aws_rds_cluster.aurora.database_name}"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${local.name}-app-secrets"
  description = "Application secrets for ${local.name}"

  tags = merge(local.tags, {
    Name    = "${local.name}-app-secrets"
    Purpose = "Application configuration secrets"
  })
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    SESSION_SECRET = random_password.session_secret.result
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "random_password" "session_secret" {
  length  = 64
  special = false
}
