resource "azurerm_user_assigned_identity" "arc_identity" {
  name                          = "${var.prefix}-id"
  resource_group_name           = var.rg_name
  location                      = var.location
}

resource "azurerm_role_assignment" "arc_vnet_contributor" {
  scope                         = var.vnet_id
  role_definition_name          = "Network Contributor"
  principal_id                  = azurerm_user_assigned_identity.arc_identity.principal_id
}

resource "azurerm_kubernetes_cluster" "arc_cluster" {
  name                          = "${var.prefix}-cluster"
  location                      = var.location
  resource_group_name           = var.rg_name
  dns_prefix                    = "${var.prefix}-dns"
  private_cluster_enabled       = true

  api_server_access_profile {
    virtual_network_integration_enabled = true
    subnet_id                           = var.api_server_subnet_id
  }

  default_node_pool {
    name                        = "arcnodepool"
    node_count                  = var.node_count
    vm_size                     = var.vm_size
    vnet_subnet_id              = var.nodes_subnet_id
  }

  identity {
    type                        = "UserAssigned"
    identity_ids                = [azurerm_user_assigned_identity.arc_identity.id]
  }

  network_profile {
    network_plugin              = "azure"
    network_plugin_mode         = "overlay"
    network_data_plane          = "cilium"
    network_policy              = "cilium"
    service_cidr                = var.service_cidr
    dns_service_ip              = var.dns_service_ip
  }

  depends_on = [ azurerm_role_assignment.arc_vnet_contributor ]
}