output "vnet_id" {
    value = azurerm_virtual_network.arc_vnet.id
}

output "api_server_subnet_id" {
    value = azurerm_subnet.arc_api_server.id
}

output "nodes_subnet_id" {
    value = azurerm_subnet.arc_nodes.id
}