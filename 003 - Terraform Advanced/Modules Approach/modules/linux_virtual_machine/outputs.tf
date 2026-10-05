output "id" {
  description = "Resource ID of the Virtual Machine."
  value       = azurerm_linux_virtual_machine.this.id
}

output "name" {
  description = "Name of the Virtual Machine."
  value       = azurerm_linux_virtual_machine.this.name
}

output "principal_id" {
  description = "Principal ID of the Virtual Machine system-assigned managed identity."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "network_interface_id" {
  description = "Resource ID of the Virtual Machine Network Interface."
  value       = azurerm_network_interface.this.id
}
