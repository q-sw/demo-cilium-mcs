# --- Paris Compute Instances ---

resource "google_compute_instance" "cp_paris" {
  name         = "cp-paris"
  machine_type = var.machine_type
  zone         = "${var.region_paris}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_paris.self_link
    access_config {} # Public IP
    # No access_config block = No Public IP
  }

  can_ip_forward = true
  tags           = ["k8s-node", "paris"]

  labels = {
    k8s-role     = "control-plane"
    cluster-name = "paris"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    #ssh-keys       = "ubuntu:${file(var.ssh_pub_key_path)}"
  }
}

resource "google_compute_instance" "worker_paris" {
  name         = "worker-paris"
  machine_type = var.machine_type
  zone         = "${var.region_paris}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_paris.self_link
    access_config {} # Public IP
  }

  can_ip_forward = true
  tags           = ["k8s-node", "paris"]

  labels = {
    k8s-role     = "worker"
    cluster-name = "paris"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    #ssh-keys       = "ubuntu:${file(var.ssh_pub_key_path)}"
  }
}

# --- New York Compute Instances ---

resource "google_compute_instance" "cp_newyork" {
  name         = "cp-newyork"
  machine_type = var.machine_type
  zone         = "${var.region_newyork}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_newyork.self_link
    access_config {} # Public IP
  }

  can_ip_forward = true
  tags           = ["k8s-node", "newyork"]

  labels = {
    k8s-role     = "control-plane"
    cluster-name = "newyork"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "ubuntu:${file(var.ssh_pub_key_path)}"
  }
}

resource "google_compute_instance" "worker_newyork" {
  name         = "worker-newyork"
  machine_type = var.machine_type
  zone         = "${var.region_newyork}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_newyork.self_link
    access_config {} # Public IP
  }

  can_ip_forward = true
  tags           = ["k8s-node", "newyork"]

  labels = {
    k8s-role     = "worker"
    cluster-name = "newyork"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "ubuntu:${file(var.ssh_pub_key_path)}"
  }
}

# --- Instance Groups ---
resource "google_compute_instance_group" "paris_nodes" {
  name        = "k8s-nodes-paris"
  description = "Unmanaged Instance Group for Paris K8s Nodes"
  zone        = "${var.region_paris}-b"

  instances = [
    google_compute_instance.cp_paris.self_link,
    google_compute_instance.worker_paris.self_link
  ]

  named_port {
    name = "http"
    port = 30080
  }

  named_port {
    name = "https"
    port = 443
  }
}

resource "google_compute_instance_group" "newyork_nodes" {
  name        = "k8s-nodes-newyork"
  description = "Unmanaged Instance Group for New York K8s Nodes"
  zone        = "${var.region_newyork}-b"

  instances = [
    google_compute_instance.cp_newyork.self_link,
    google_compute_instance.worker_newyork.self_link
  ]

  named_port {
    name = "http"
    port = 30080
  }

  named_port {
    name = "https"
    port = 443
  }
}
