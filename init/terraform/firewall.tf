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

# Allow traffic from New York VPC (for Cluster Mesh)
resource "google_compute_firewall" "allow_from_ny" {
  name    = "fw-paris-allow-from-ny"
  network = google_compute_network.vpc_paris.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_newyork]
}


# --- Firewall New York ---

# Allow SSH from Public IP (User)
resource "google_compute_firewall" "allow_public_access_newyork" {
  name    = "fw-newyork-allow-public-access"
  network = google_compute_network.vpc_newyork.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "30000-32767"]
  }

  source_ranges = var.authorized_source_ranges
}

# Allow SSH from IAP
resource "google_compute_firewall" "allow_ssh_iap_newyork" {
  name    = "fw-newyork-allow-ssh-iap"
  network = google_compute_network.vpc_newyork.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Allow Internal traffic within New York VPC
resource "google_compute_firewall" "allow_internal_newyork" {
  name    = "fw-newyork-allow-internal"
  network = google_compute_network.vpc_newyork.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_newyork]
}

# Allow traffic from Paris VPC (for Cluster Mesh)
resource "google_compute_firewall" "allow_from_paris" {
  name    = "fw-newyork-allow-from-paris"
  network = google_compute_network.vpc_newyork.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.cidr_paris]
}
