locals {
  allowed_regions = ["canadacentral", "canadaeast"]
  allowed_env     = ["prod", "dev", "uat"]
  region_codes = {
    "canadacentral" = "cc"
    "canadaeast"    = "ce"
  }
  common_tags = merge(
    var.mandatory_tags,
    {
      managedBy    = "Terraform"
      creationTime = formatdate("YYYY-MM-DD hh:mm", timestamp())
    }
  )
  env_config = {
    prod = {
      address     = "10.50.0.0/16"
      replication = "GRS"
    }
    dev = {
      address     = "10.60.0.0/16"
      replication = "LRS"
    }
    uat = {
      address     = "10.70.0.0/16"
      replication = "LRS"
    }
  }
  address_space    = lookup(local.env_config, var.env).address
  replication_type = lookup(local.env_config, var.env).replication
  region_short     = lookup(local.region_codes, replace(lower(var.region), " ", ""))

  network_security_group_rules = [
    {
      name                   = "Allow-RDP"
      direction              = "Inbound"
      priority               = 200
      destination_port_range = "3389"
      source_address_prefix  = "VirtualNetwork"
    },
    {
      name                   = "Deny-HTTP"
      direction              = "Inbound"
      priority               = 300
      destination_port_range = "80"
      access                 = "Deny"
    },
    {
      name                   = "Allow-HTTPS"
      direction              = "Inbound"
      priority               = 100
      destination_port_range = "443"
    },
    {
      name                   = "Allow-DNS"
      direction              = "Outbound"
      priority               = 400
      protocol               = "Udp"
      destination_port_range = "53"
    },
    {
      name                   = "Allow-NTP"
      direction              = "Outbound"
      priority               = 500
      protocol               = "Udp"
      destination_port_range = "123"
    }
  ]
}

data "azurerm_subscription" "current" {
  subscription_id = var.sub_id
  lifecycle {
    postcondition {
      condition = (
        var.env == self.tags["env_short"]
      )
      error_message = <<-EOF
        The Selected Environment does not match subscriptiopn's env_short tag.

        Selected Environment    : ${var.env}
        Selected Subscription   : ${var.sub_id}
        Subscription Tag        : ${self.tags["env_short"]} 
    EOF
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = format("rg-%s-%s-001", var.env, local.region_short)
  location = var.region
  tags = merge(
    local.common_tags,
    {
      projectName = "Terraform102"
      application = "Core Infrastructure"
    }
  )
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env}-${local.region_short}-001"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.address_space]
  tags = merge(
    local.common_tags,
    {
      "cost-centre" = "4001"
    }
  )
  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_subnet" "subnets" {
  for_each                        = var.subnets
  name                            = "subnet-${var.env}-${local.region_short}-${each.key}"
  virtual_network_name            = azurerm_virtual_network.vnet.name
  resource_group_name             = azurerm_resource_group.rg.name
  address_prefixes                = [cidrsubnet(local.address_space, 8, each.value.subnet_position)]
  default_outbound_access_enabled = try(each.value.default_outbound_access_enabled, null)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [1] : []
    content {
      name = "delegation"
      service_delegation {
        name    = each.value.delegation
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }

  lifecycle {
    ignore_changes = [delegation]
  }
}

resource "azurerm_network_security_group" "nsg" {
  count               = var.env == "prod" ? 1 : 0
  name                = "nsg-${var.env}-${local.region_short}-001"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  dynamic "security_rule" {
    for_each = local.network_security_group_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = lookup(security_rule.value, "access", "Allow")
      protocol                   = lookup(security_rule.value, "protocol", "Tcp")
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", "*")
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", "*")
    }
  }


  lifecycle {
    precondition {
      condition = alltrue([
        for rule in local.network_security_group_rules :
        rule.priority >= 100 && rule.priority <= 4096
      ])
      error_message = "All NSG rule priorities must be between 100 and 4096."
    }
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = var.env == "prod" ? 1 : 0
  subnet_id                 = azurerm_subnet.subnets["general"].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}


resource "azurerm_resource_group" "rg2" {
  provider = azurerm.mgmt_sub
  name     = "rg-mgmt-cc-001"
  location = "canadacentral"
}

resource "azurerm_virtual_network" "mgmt_vnet" {
  provider = azurerm.mgmt_sub
  name                = "vnet-mgmt-cc-001"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  address_space       = ["10.90.0.0/16"]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["creationTime"],
      tags["creator"],
      tags["creatorType"]
    ]
  }
}

resource "azurerm_virtual_network_peering" "main_to_mgmt" {
  name                      = "peer-main-to-mgmt"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.mgmt_vnet.id
}
resource "azurerm_virtual_network_peering" "mgmt_to_main" {
  provider = azurerm.mgmt_sub
  name                      = "peer-mgmt-to-main"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = azurerm_virtual_network.mgmt_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}