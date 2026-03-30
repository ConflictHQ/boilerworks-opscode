output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.autopilot.name
}

output "endpoint" {
  description = "GKE cluster API endpoint"
  value       = google_container_cluster.autopilot.endpoint
}

output "workload_identity_sa" {
  description = "Workload identity service account email"
  value       = google_service_account.gke_workload.email
}
