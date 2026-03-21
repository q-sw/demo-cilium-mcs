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

# --- VPC Amsterdam ---
resource "google_compute_network" "vpc_amsterdam" {
  name                    = "vpc-dc-amsterdam"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute,
    google_project_service.cloudresourcemanager
  ]
}

resource "google_compute_subnetwork" "subnet_amsterdam" {
  name          = "subnet-dc-amsterdam"
  ip_cidr_range = var.cidr_amsterdam
  region        = var.region_amsterdam
  network       = google_compute_network.vpc_amsterdam.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_amsterdam
  }

  secondary_ip_range {
    range_name    = "lb-alias"
    ip_cidr_range = var.lb_cidr_amsterdam
  }
}

# Proxy-only subnet for Amsterdam
resource "google_compute_subnetwork" "proxy_subnet_amsterdam" {
  name          = "proxy-subnet-amsterdam"
  ip_cidr_range = "10.130.0.0/23"
  region        = var.region_amsterdam
  network       = google_compute_network.vpc_amsterdam.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# --- VPC Peering (Bidirectional) ---
resource "google_compute_network_peering" "peering_paris_to_ams" {
  name         = "peering-paris-to-ams"
  network      = google_compute_network.vpc_paris.self_link
  peer_network = google_compute_network.vpc_amsterdam.self_link
}

resource "google_compute_network_peering" "peering_ams_to_paris" {
  name         = "peering-ams-to-paris"
  network      = google_compute_network.vpc_amsterdam.self_link
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

# --- Cloud NAT Amsterdam ---
resource "google_compute_router" "router_amsterdam" {
  name    = "router-amsterdam"
  region  = var.region_amsterdam
  network = google_compute_network.vpc_amsterdam.id
}

resource "google_compute_router_nat" "nat_amsterdam" {
  name                               = "nat-amsterdam"
  router                             = google_compute_router.router_amsterdam.name
  region                             = var.region_amsterdam
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
