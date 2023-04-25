output "resource_group_name" {
  value = azurerm_resource_group.vault.name
}

output "network_name" {
  value = azurerm_virtual_network.tf_network.name
}