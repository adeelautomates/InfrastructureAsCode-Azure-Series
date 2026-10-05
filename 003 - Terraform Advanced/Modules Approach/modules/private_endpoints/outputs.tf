output "id" {
  description = "Resource ID of the Private Endpoint."
  value       = azurerm_private_endpoint.this.id
}

output "name" {
  description = "Name of the Private Endpoint."
  value       = azurerm_private_endpoint.this.name
}

output "private_ip_address" {
  description = "Private IP address assigned to the Private Endpoint."
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}