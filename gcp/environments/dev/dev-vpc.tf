# -----------------------------------------------------------------------------
# VPC + Subnets + Cloud NAT
# -----------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = "${local.name}-vpc"
  auto_create_subnetworks = false
  project                 = local.project_id
}

resource "google_compute_subnetwork" "public" {
  name          = "${local.name}-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = local.region
  network       = google_compute_network.vpc.id
  project       = local.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private" {
  name                     = "${local.name}-private"
  ip_cidr_range            = "10.0.11.0/24"
  region                   = local.region
  network                  = google_compute_network.vpc.id
  project                  = local.project_id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # Secondary ranges for GKE pods/services (used if GKE is enabled)
  secondary_ip_range {
    range_name    = "${local.name}-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${local.name}-services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# -----------------------------------------------------------------------------
# Cloud Router + Cloud NAT (single NAT for dev — cost savings)
# -----------------------------------------------------------------------------

resource "google_compute_router" "router" {
  name    = "${local.name}-router"
  region  = local.region
  network = google_compute_network.vpc.id
  project = local.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.name}-nat"
  router                             = google_compute_router.router.name
  region                             = local.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = local.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${local.name}-allow-health-checks"
  network = google_compute_network.vpc.id
  project = local.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "8080"]
  }

  # Google Cloud health check IP ranges
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  target_tags = ["${local.name}-allow-hc"]
  description = "Allow Google Cloud health check probes"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${local.name}-allow-internal"
  network = google_compute_network.vpc.id
  project = local.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/16"]
  description   = "Allow internal VPC traffic"
}

resource "google_compute_firewall" "deny_all_ingress" {
  name     = "${local.name}-deny-all-ingress"
  network  = google_compute_network.vpc.id
  project  = local.project_id
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Default deny all ingress"
}
