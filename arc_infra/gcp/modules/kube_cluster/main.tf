resource "google_container_cluster" "primary" {
  name                      = "${var.prefix}-cluster"
  location                  = var.zone_name
  deletion_protection       = false
  remove_default_node_pool  = true
  initial_node_count        = var.kube_cluster_node_count
  network                   = var.vpc_self_link
  subnetwork                = var.subnet_self_link
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.prefix}-pods"
    services_secondary_range_name = "${var.prefix}-svc"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0" 
      display_name = "Allow-All"
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "${var.prefix}-node-pool"
  location   = google_container_cluster.primary.location
  cluster    = google_container_cluster.primary.name
  node_count = var.kube_cluster_node_count

  node_config {
    preemptible  = true
    machine_type = var.kube_cluster_machine_type
    service_account = var.svc_account_mail
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  upgrade_settings {
    strategy = "SURGE"
    max_surge = 1
    max_unavailable = 0
  }
}