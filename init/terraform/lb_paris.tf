# --- Load Balancer Paris (Regional HTTP Proxy) ---

# 1. Health Check
resource "google_compute_region_health_check" "hc_cilium_gateway" {
  name   = "hc-cilium-gateway"
  region = var.region_paris

  tcp_health_check {
    port = "30080"
  }
}

# 2. Backend Service (HTTP)
resource "google_compute_region_backend_service" "cilium_backend_service" {
  name                  = "cilium-backend-service"
  region                = var.region_paris
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.hc_cilium_gateway.id]
  port_name             = "http"

  backend {
    group           = google_compute_instance_group.paris_nodes.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# 3. URL Map
resource "google_compute_region_url_map" "cilium_url_map" {
  name            = "cilium-url-map"
  region          = var.region_paris
  default_service = google_compute_region_backend_service.cilium_backend_service.id
}

# 4. Target HTTP Proxy
resource "google_compute_region_target_http_proxy" "cilium_http_proxy" {
  name    = "cilium-http-proxy"
  region  = var.region_paris
  url_map = google_compute_region_url_map.cilium_url_map.id
}

# 5. Forwarding Rule
resource "google_compute_forwarding_rule" "cilium_external_lb" {
  name                  = "cilium-external-lb"
  region                = var.region_paris
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.cilium_http_proxy.id
  network               = google_compute_network.vpc_paris.id
}
