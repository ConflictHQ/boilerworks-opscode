# -----------------------------------------------------------------------------
# Boilerworks — GCP Staging Environment
#
# Staging mirrors production topology at reduced scale.
# See dev/main.tf for planned services list.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # backend "gcs" {
  #   bucket = "tf-state-boilerworks"
  #   prefix = "gcp/stg"
  # }
}
