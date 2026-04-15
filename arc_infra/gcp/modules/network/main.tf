resource "google_compute_network" "vpc_network" {
  name                              = "${var.prefix}-vpc"
  auto_create_subnetworks           = false  
  delete_default_routes_on_create   = true
}

resource "google_compute_subnetwork" "gke_subnet" {
  name                     = "${var.prefix}-subnet"
  ip_cidr_range            = var.cidr_range
  region                   = var.region_name
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.prefix}-pods"
    ip_cidr_range = var.pods_ip_range
  }

  secondary_ip_range {
    range_name    = "${var.prefix}-svc"
    ip_cidr_range = var.svc_ip_range
  }
}

resource "google_compute_global_address" "private_ip_range" {
  name            = "${var.prefix}-control-plane-ip"
  purpose         = "VPC_PEERING"
  address_type    = "INTERNAL"
  prefix_length   = 28
  network         = google_compute_network.vpc_network.id
}

resource "google_compute_router" "arc_vpc_router" {
  name            = "${var.prefix}-router"
  network         = google_compute_network.vpc_network.name
  region          = var.region_name
  project         = var.project_id
}

resource "google_compute_router_nat" "arc_vpc_nat" {
  name                                = "${var.prefix}-nat"
  router                              = google_compute_router.arc_vpc_router.name
  region                              = google_compute_router.arc_vpc_router.region
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option              = "AUTO_ONLY"
  project                             = var.project_id
  min_ports_per_vm                    = 64
}

resource "google_compute_firewall" "allow_egress_https" {
  name                = "${var.prefix}-allow-egress-https"
  network             = google_compute_network.vpc_network.name
  direction           = "EGRESS"
  priority            = 1000
  allow {
    protocol          = "tcp"
    ports             = ["443"]
  }
  destination_ranges  = ["0.0.0.0/0"]
  description         = "Allow HTTPS egress"
}

resource "google_compute_route" "default_internet_route" {
  name             = "default-internet-gateway-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}