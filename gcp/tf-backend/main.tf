# -----------------------------------------------------------------------------
# Boilerworks — GCP Terraform State Backend
#
# Creates a GCS bucket for Terraform remote state.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

resource "google_storage_bucket" "tfstate" {
  name          = "tf-state-${var.project_id}"
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  labels = {
    service    = "boilerworks"
    managed-by = "terraform"
    purpose    = "tfstate"
  }
}

output "bucket_name" {
  description = "GCS bucket name for Terraform state"
  value       = google_storage_bucket.tfstate.name
}
