output "id" {
  description = "Resource ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary Blob service endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}