output "lb_ip" {
  description = "HTTPS load balancer IP address"
  value       = google_compute_global_forwarding_rule.https.ip_address
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.app.uri
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.app.name
}
