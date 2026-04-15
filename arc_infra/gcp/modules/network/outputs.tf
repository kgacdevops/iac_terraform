output "vpc_self_link" {
    value = google_compute_network.vpc_network.self_link
}

output "subnet_self_link" {
    value = google_compute_subnetwork.gke_subnet.self_link
}