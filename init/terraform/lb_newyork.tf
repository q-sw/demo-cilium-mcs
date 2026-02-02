# --- Load Balancer New York (Regional HTTP Proxy) ---

# 1. Health Check
resource "google_compute_region_health_check" "hc_cilium_gateway_newyork" {
  name   = "hc-cilium-gateway-newyork"
  region = var.region_newyork

  tcp_health_check {
    port = "30080"
  }
}

# 2. Backend Service (HTTP)
resource "google_compute_region_backend_service" "cilium_backend_service_newyork" {
  name                  = "cilium-backend-service-newyork"
  region                = var.region_newyork
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.hc_cilium_gateway_newyork.id]
  port_name             = "http"

  backend {
    group           = google_compute_instance_group.newyork_nodes.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# 3. URL Map
resource "google_compute_region_url_map" "cilium_url_map_newyork" {
  name            = "cilium-url-map-newyork"
  region          = var.region_newyork
  default_service = google_compute_region_backend_service.cilium_backend_service_newyork.id
}

# 4. Target HTTP Proxy
resource "google_compute_region_target_http_proxy" "cilium_http_proxy_newyork" {
  name    = "cilium-http-proxy-newyork"
  region  = var.region_newyork
  url_map = google_compute_region_url_map.cilium_url_map_newyork.id
}

# 5. Forwarding Rule
resource "google_compute_forwarding_rule" "cilium_external_lb_newyork" {
  name                  = "cilium-external-lb-newyork"
  region                = var.region_newyork
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.cilium_http_proxy_newyork.id
  network               = google_compute_network.vpc_newyork.id
}
