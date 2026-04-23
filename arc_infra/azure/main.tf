resource "azurerm_resource_group" "arc_rg" {
  name     = "${var.prefix}-aks-rg"
  location = var.location
}

module "network" {
    source            = "./modules/network"
    prefix            = var.prefix
    location          = azurerm_resource_group.arc_rg.location
    rg_name           = azurerm_resource_group.arc_rg.name
    vnet_cidr         = var.vnet_cidr
    subnet_node_cidr  = var.subnet_node_cidr
    subnet_api_cidr   = var.subnet_api_cidr
}

module "kube_cluster" {
    source                = "./modules/kube_cluster"
    prefix                = var.prefix
    node_count            = var.node_count
    vm_size               = var.vm_size
    location              = azurerm_resource_group.arc_rg.location
    rg_name               = azurerm_resource_group.arc_rg.name
    vnet_id               = module.network.vnet_id 
    api_server_subnet_id  = module.network.api_server_subnet_id
    nodes_subnet_id       = module.network.nodes_subnet_id
    service_cidr          = var.service_cidr
    dns_service_ip        = var.dns_service_ip
    depends_on            = [ module.network ]
}

module "install_arc" {
    source                  = "../arc_install"
    prefix                  = var.prefix
    gh_app_id               = var.gh_app_id
    gh_app_installation_id  = var.gh_app_installation_id
    github_owner            = var.github_owner
    cloud_provider          = var.cloud_provider
}