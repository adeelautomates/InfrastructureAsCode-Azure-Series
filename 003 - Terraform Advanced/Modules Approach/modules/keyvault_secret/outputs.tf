output "value" {
  description = "Value stored in the Key Vault secret."
  value       = azurerm_key_vault_secret.this.value
  sensitive   = true
}

output "id" {
  description = "Resource ID of the Key Vault secret."
  value       = azurerm_key_vault_secret.this.resource_versionless_id
}