# EXPERIMENTAL — In Progress
# GCP support is under active development. Not yet validated against
# a live GCP project. Contributions welcome.

# -----------------------------------------------------------------------------
# Boilerworks — GCP Development Environment
# -----------------------------------------------------------------------------

terraform {
  # Backend configured via -backend-config at init time.
  # Project/region come from variables.tf (via -var flags or a tfvars file).
  # Run: ./run.sh init gcp dev
  #
  # backend "gcs" {
  #   bucket = "tf-state-boilerworks"
  #   prefix = "gcp/dev"
  # }
}

locals {
  name         = "dev-boilerworks"
  env          = "development"
  region       = var.region
  project_id   = var.project_id
  service_name = "boilerworks"
  owner        = "conflict"
  ver          = "1.0"
  domain       = "dev.boilerworks.net"
  vpc_cidr     = "10.0.0.0/16"

  labels = {
    service     = local.service_name
    environment = local.env
    owner       = local.owner
    managed-by  = "terraform"
  }
}

data "google_project" "current" {
  project_id = local.project_id
}

data "google_client_config" "current" {}
