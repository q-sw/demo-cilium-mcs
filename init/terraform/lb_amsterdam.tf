# --- Load Balancer Amsterdam (Regional HTTP Proxy) ---

# 1. Health Check
resource "google_compute_region_health_check" "hc_cilium_gateway_amsterdam" {
  name   = "hc-cilium-gateway-amsterdam"
  region = var.region_amsterdam

  tcp_health_check {
    port = "30080"
  }
}

# 2. Backend Service (HTTP)
resource "google_compute_region_backend_service" "cilium_backend_service_amsterdam" {
  name                  = "cilium-backend-service-amsterdam"
  region                = var.region_amsterdam
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.hc_cilium_gateway_amsterdam.id]
  port_name             = "http"

  backend {
    group           = google_compute_instance_group.amsterdam_nodes.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# 3. URL Map
resource "google_compute_region_url_map" "cilium_url_map_amsterdam" {
  name            = "cilium-url-map-amsterdam"
  region          = var.region_amsterdam
  default_service = google_compute_region_backend_service.cilium_backend_service_amsterdam.id
}

# 4. Target HTTP Proxy
resource "google_compute_region_target_http_proxy" "cilium_http_proxy_amsterdam" {
  name    = "cilium-http-proxy-amsterdam"
  region  = var.region_amsterdam
  url_map = google_compute_region_url_map.cilium_url_map_amsterdam.id
}

# 5. Forwarding Rule
resource "google_compute_forwarding_rule" "cilium_external_lb_amsterdam" {
  name                  = "cilium-external-lb-amsterdam"
  region                = var.region_amsterdam
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.cilium_http_proxy_amsterdam.id
  network               = google_compute_network.vpc_amsterdam.id
}
