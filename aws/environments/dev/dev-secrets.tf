# -----------------------------------------------------------------------------
# Secrets Manager
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
    username = aws_db_instance.postgres.username
    password = random_password.db_password.result
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
    url      = "postgresql://${aws_db_instance.postgres.username}:${random_password.db_password.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
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
