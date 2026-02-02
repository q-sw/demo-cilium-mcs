output "cp_paris_ip" {
  value = google_compute_instance.cp_paris.network_interface.0.network_ip
}

output "cp_newyork_ip" {
  value = google_compute_instance.cp_newyork.network_interface.0.network_ip
}

output "lb_paris_ip" {
  value = google_compute_forwarding_rule.cilium_external_lb.ip_address
}

output "lb_newyork_ip" {
  value = google_compute_forwarding_rule.cilium_external_lb_newyork.ip_address
}
