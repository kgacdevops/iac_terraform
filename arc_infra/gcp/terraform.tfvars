project_id                      = "project-235e2136-7c2e-4409-bad"
region_name                     = "us-central1"
zone_name                       = "us-central1-a"
svc_account_mail                = "terraform-gcp-sa@project-235e2136-7c2e-4409-bad.iam.gserviceaccount.com"

prefix                          = "arc-runner"
cidr_range                      = "10.0.0.0/20"
pods_ip_range                   = "10.4.0.0/14"
svc_ip_range                    = "10.0.32.0/20"

kube_cluster_node_count         = 2
kube_cluster_machine_type       = "e2-medium"