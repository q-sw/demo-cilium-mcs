output "cp_paris_ip" {
  value = google_compute_instance.cp_paris.network_interface.0.network_ip
}

output "cp_amsterdam_ip" {
  value = google_compute_instance.cp_amsterdam.network_interface.0.network_ip
}

output "lb_paris_ip" {
  value = google_compute_forwarding_rule.cilium_external_lb.ip_address
}

output "lb_amsterdam_ip" {
  value = google_compute_forwarding_rule.cilium_external_lb_amsterdam.ip_address
}
