module "network" {
    source              = "./modules/network"
    prefix              = var.prefix
    cidr_range          = var.cidr_range
    region_name         = var.region_name
    pods_ip_range       = var.pods_ip_range
    svc_ip_range        = var.svc_ip_range
    project_id          = var.project_id
}

module "kube_cluster" {
    source                      = "./modules/kube_cluster"
    vpc_self_link               = module.network.vpc_self_link
    subnet_self_link            = module.network.subnet_self_link
    prefix                      = var.prefix
    zone_name                   = var.zone_name
    kube_cluster_node_count     = var.kube_cluster_node_count
    kube_cluster_machine_type   = var.kube_cluster_machine_type
    svc_account_mail            = var.svc_account_mail
    gh_token                    = var.gh_token
    project_id                  = var.project_id
    depends_on                  = [ module.network ]
}