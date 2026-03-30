# -----------------------------------------------------------------------------
# Boilerworks — GCP Development Environment
#
# Planned services (not yet implemented):
#   - Cloud Run (compute — ECS Fargate equivalent)
#   - Cloud SQL for PostgreSQL (database)
#   - Memorystore for Redis (cache)
#   - Cloud Load Balancing (ALB equivalent)
#   - Cloud DNS (Route53 equivalent)
#   - Cloud Storage (S3 equivalent)
#   - Secret Manager (Secrets Manager equivalent)
#   - Cloud Logging + Cloud Monitoring (CloudWatch equivalent)
#   - Cloud Armor (WAF)
#   - VPC + Private Service Connect
#
# This file will be populated when GCP support is implemented.
# Follow the same patterns as the AWS implementation:
#   - Environment separation (dev/prd)
#   - Reusable modules
#   - Tagged resources (labels)
#   - Least-privilege IAM
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # backend "gcs" {
  #   bucket = "tf-state-boilerworks"
  #   prefix = "gcp/dev"
  # }
}
