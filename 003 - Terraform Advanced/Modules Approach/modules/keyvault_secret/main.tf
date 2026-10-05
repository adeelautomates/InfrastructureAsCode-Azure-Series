module "password" {
  source = "../random_password"
  length           = var.password_length
  min_lower        = var.min_lower
  min_upper        = var.min_upper
  min_numeric      = var.min_numeric
  min_special      = var.min_special
  override_special = var.override_special
}

resource "azurerm_key_vault_secret" "this" {
  name         = var.name
  value        = module.password.result
  key_vault_id = var.key_vault_id
}