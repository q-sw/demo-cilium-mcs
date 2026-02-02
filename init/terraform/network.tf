# --- VPC Paris ---
resource "google_compute_network" "vpc_paris" {
  name                    = "vpc-dc-paris"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute,
    google_project_service.cloudresourcemanager
  ]
}

resource "google_compute_subnetwork" "subnet_paris" {
  name          = "subnet-dc-paris"
  ip_cidr_range = var.cidr_paris
  region        = var.region_paris
  network       = google_compute_network.vpc_paris.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_paris
  }

  secondary_ip_range {
    range_name    = "lb-alias"
    ip_cidr_range = var.lb_cidr_paris
  }
}

# Proxy-only subnet for Paris (Required for Regional Envoy-based LBs)
resource "google_compute_subnetwork" "proxy_subnet_paris" {
  name          = "proxy-subnet-paris"
  ip_cidr_range = "10.129.0.0/23"
  region        = var.region_paris
  network       = google_compute_network.vpc_paris.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# --- VPC New York ---
resource "google_compute_network" "vpc_newyork" {
  name                    = "vpc-dc-newyork"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute,
    google_project_service.cloudresourcemanager
  ]
}

resource "google_compute_subnetwork" "subnet_newyork" {
  name          = "subnet-dc-newyork"
  ip_cidr_range = var.cidr_newyork
  region        = var.region_newyork
  network       = google_compute_network.vpc_newyork.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_newyork
  }

  secondary_ip_range {
    range_name    = "lb-alias"
    ip_cidr_range = var.lb_cidr_newyork
  }
}

# Proxy-only subnet for New York
resource "google_compute_subnetwork" "proxy_subnet_newyork" {
  name          = "proxy-subnet-newyork"
  ip_cidr_range = "10.130.0.0/23"
  region        = var.region_newyork
  network       = google_compute_network.vpc_newyork.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# --- VPC Peering (Bidirectional) ---
resource "google_compute_network_peering" "peering_paris_to_ny" {
  name         = "peering-paris-to-ny"
  network      = google_compute_network.vpc_paris.self_link
  peer_network = google_compute_network.vpc_newyork.self_link
}

resource "google_compute_network_peering" "peering_ny_to_paris" {
  name         = "peering-ny-to-paris"
  network      = google_compute_network.vpc_newyork.self_link
  peer_network = google_compute_network.vpc_paris.self_link
}

# --- Cloud NAT Paris (For internet access without Public IPs) ---
resource "google_compute_router" "router_paris" {
  name    = "router-paris"
  region  = var.region_paris
  network = google_compute_network.vpc_paris.id
}

resource "google_compute_router_nat" "nat_paris" {
  name                               = "nat-paris"
  router                             = google_compute_router.router_paris.name
  region                             = var.region_paris
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# --- Cloud NAT New York ---
resource "google_compute_router" "router_newyork" {
  name    = "router-newyork"
  region  = var.region_newyork
  network = google_compute_network.vpc_newyork.id
}

resource "google_compute_router_nat" "nat_newyork" {
  name                               = "nat-newyork"
  router                             = google_compute_router.router_newyork.name
  region                             = var.region_newyork
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
