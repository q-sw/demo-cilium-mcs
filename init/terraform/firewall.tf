# --- Firewall Paris ---

# Allow SSH from Public IP (User)
resource "google_compute_firewall" "allow_public_public_paris" {
  name    = "fw-paris-allow-public-acces"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "30000-32767"]
  }

  source_ranges = var.authorized_source_ranges
}

# Allow SSH from IAP (Identity-Aware Proxy)
resource "google_compute_firewall" "allow_ssh_iap_paris" {
  name    = "fw-paris-allow-ssh-iap"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Allow Internal traffic within Paris VPC
resource "google_compute_firewall" "allow_internal_paris" {
  name    = "fw-paris-allow-internal"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_paris]
}

# Allow traffic from Amsterdam VPC (for Cluster Mesh)
resource "google_compute_firewall" "allow_from_ams" {
  name    = "fw-paris-allow-from-ams"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_amsterdam]
}

# --- Gateway API / Load Balancer Rules (Paris) ---

# Allow traffic from Proxy Subnet to Gateway (NodePort)
resource "google_compute_firewall" "allow_proxy_subnet_paris" {
  name    = "allow-proxy-subnet-paris"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Allow GCP Health Checks
resource "google_compute_firewall" "allow_gcp_health_checks" {
  name    = "allow-gcp-health-checks"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}


# --- Firewall Amsterdam ---

# Allow SSH from Public IP (User)
resource "google_compute_firewall" "allow_public_access_amsterdam" {
  name    = "fw-amsterdam-allow-public-access"
  network = google_compute_network.vpc_amsterdam.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "30000-32767"]
  }

  source_ranges = var.authorized_source_ranges
}

# Allow SSH from IAP
resource "google_compute_firewall" "allow_ssh_iap_amsterdam" {
  name    = "fw-amsterdam-allow-ssh-iap"
  network = google_compute_network.vpc_amsterdam.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Allow Internal traffic within Amsterdam VPC
resource "google_compute_firewall" "allow_internal_amsterdam" {
  name    = "fw-amsterdam-allow-internal"
  network = google_compute_network.vpc_amsterdam.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_amsterdam]
}

# Allow traffic from Paris VPC (for Cluster Mesh)
resource "google_compute_firewall" "allow_from_paris" {
  name    = "fw-amsterdam-allow-from-paris"
  network = google_compute_network.vpc_amsterdam.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_paris]
}

# --- Gateway API / Load Balancer Rules (Amsterdam) ---

# Allow traffic from Proxy Subnet to Gateway (NodePort)
resource "google_compute_firewall" "allow_proxy_subnet_amsterdam" {
  name    = "allow-proxy-subnet-amsterdam"
  network = google_compute_network.vpc_amsterdam.name

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Allow GCP Health Checks for Amsterdam
resource "google_compute_firewall" "allow_gcp_health_checks_amsterdam" {
  name    = "allow-gcp-health-checks-amsterdam"
  network = google_compute_network.vpc_amsterdam.name

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}
