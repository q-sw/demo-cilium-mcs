# --- Cloud DNS Private Zone ---

resource "google_dns_managed_zone" "internal" {
  name        = "internal-zone"
  dns_name    = "internal."
  description = "Private DNS zone for internal cluster communication"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_paris.id
    }
    networks {
      network_url = google_compute_network.vpc_newyork.id
    }
  }

  depends_on = [
    google_project_service.dns
  ]
}

# --- DNS Records ---

resource "google_dns_record_set" "cp_paris" {
  name         = "cp.paris.${google_dns_managed_zone.internal.dns_name}"
  managed_zone = google_dns_managed_zone.internal.name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_instance.cp_paris.network_interface.0.network_ip]
}

resource "google_dns_record_set" "cp_newyork" {
  name         = "cp.newyork.${google_dns_managed_zone.internal.dns_name}"
  managed_zone = google_dns_managed_zone.internal.name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_instance.cp_newyork.network_interface.0.network_ip]
}

# --- Cluster Mesh Records ---

resource "google_dns_record_set" "clustermesh_paris" {
  name         = "cp.paris.clustermesh.${google_dns_managed_zone.internal.dns_name}"
  managed_zone = google_dns_managed_zone.internal.name
  type         = "A"
  ttl          = 300

  rrdatas = [
    google_compute_instance.cp_paris.network_interface.0.network_ip,
    google_compute_instance.worker_paris.network_interface.0.network_ip
  ]
}

resource "google_dns_record_set" "clustermesh_newyork" {
  name         = "cp.newyork.clustermesh.${google_dns_managed_zone.internal.dns_name}"
  managed_zone = google_dns_managed_zone.internal.name
  type         = "A"
  ttl          = 300

  rrdatas = [
    google_compute_instance.cp_newyork.network_interface.0.network_ip,
    google_compute_instance.worker_newyork.network_interface.0.network_ip
  ]
}
