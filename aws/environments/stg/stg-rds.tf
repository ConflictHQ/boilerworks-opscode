# -----------------------------------------------------------------------------
# RDS PostgreSQL 16 (staging — standard instance, multi-AZ)
# -----------------------------------------------------------------------------

resource "aws_db_instance" "postgres" {
  identifier = "${local.name}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = 50
  max_allocated_storage = 200
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "boilerworks"
  username = "boilerworks"
  password = random_password.db_password.result

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  parameter_group_name = aws_db_parameter_group.postgres.name

  backup_retention_period = 14
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-db-final"
  deletion_protection       = true

  performance_insights_enabled = true

  tags = merge(local.tags, {
    Name   = "${local.name}-db"
    Engine = "postgres-16"
  })

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${local.name}-pg16"
  family      = "postgres16"
  description = "PostgreSQL 16 parameter group for ${local.name}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "60000"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-pg16-params"
  })
}

resource "random_password" "db_password" {
  length  = 32
  special = false
}
