resource "azurerm_virtual_network" "arc_vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "arc_nodes" {
  name                 = "${var.prefix}-subnet-nodes"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.arc_vnet.name
  address_prefixes     = [var.subnet_node_cidr]
}

resource "azurerm_subnet" "arc_api_server" {
  name                 = "${var.prefix}-subnet-api-server"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.arc_vnet.name
  address_prefixes     = [var.subnet_api_cidr]

  delegation {
    name = "${var.prefix}-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}