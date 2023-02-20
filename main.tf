# creates resource group for network infra
resource "azurerm_resource_group" "network" {
  name     = "trace-network-rg"
  location = "East US"
}


# Builds 4 conseq. /16 vnets
resource "azurerm_virtual_network" "trace" {
  for_each            = { "hub" = 1, "dmz" = 2, "app" = 3, "db" = 4 }
  name                = "${var.network_name}_${each.key}_vnet"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = [cidrsubnet("${var.supernet}", 8, each.value)]

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

# creates a peering between hub and each spoke vnet
resource "azurerm_virtual_network_peering" "hub" {
  for_each                     = { for k, v in azurerm_virtual_network.trace : k => v.id if k != "hub" }
  name                         = "vnet_peering_hub_to_${each.key}"
  resource_group_name          = azurerm_resource_group.network.name
  virtual_network_name         = azurerm_virtual_network.trace["hub"].name
  remote_virtual_network_id    = each.value
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# creates a peering between each spoke vnet and the hub vnet
resource "azurerm_virtual_network_peering" "spokes" {
  for_each                     = { for k, v in azurerm_virtual_network.trace : k => v.name if k != "hub" }
  name                         = "vnet_peering_${each.key}_to_hub"
  resource_group_name          = azurerm_resource_group.network.name
  virtual_network_name         = each.value
  remote_virtual_network_id    = azurerm_virtual_network.trace["hub"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# creates 2 x /25 subnets for inside and outside fw interfaces
resource "azurerm_subnet" "hub" {
  for_each = {
    "outside" = cidrsubnet(element(azurerm_virtual_network.trace["hub"].address_space, 0), 9, 0)
    "inside"  = cidrsubnet(element(azurerm_virtual_network.trace["hub"].address_space, 0), 9, 1)
  }
  name                 = "hub_${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.trace["hub"].name
  address_prefixes     = [each.value]
}

# creates a route table for the hub outside subnet
resource "azurerm_route_table" "hub_outside" {
  name                          = "hub_outside_rt"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  disable_bgp_route_propagation = false

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

# creates a route table for the hub inside subnet
resource "azurerm_route_table" "hub_inside" {
  name                          = "hub_inside_rt"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  disable_bgp_route_propagation = false

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

# creates a spoke subnet for each entry in var.subnet_params and assigns to vnet listed in "vnet" argument
resource "azurerm_subnet" "spoke" {
  for_each             = var.subnet_params
  name                 = "${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.trace["${each.value.vnet}"].name
  address_prefixes     = [each.value.cidr]
}

# creates a route table for each spoke vnet
resource "azurerm_route_table" "spokes" {
  for_each                      = { for k, v in azurerm_virtual_network.trace : k => v if k != "hub" }
  name                          = "${each.key}_main_rt"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  disable_bgp_route_propagation = false

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

# creates 2 x  NSG for hub subnets
resource "azurerm_network_security_group" "hub" {
  for_each            = azurerm_subnet.hub
  name                = "hub_${each.key}_nsg"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

# associates hub nsgs to appropriate hub subnet
resource "azurerm_subnet_network_security_group_association" "hub" {
  for_each                  = azurerm_subnet.hub
  subnet_id                 = azurerm_subnet.hub[each.key].id
  network_security_group_id = azurerm_network_security_group.hub[each.key].id
}

# allow all outbound rule for hub nsgs
resource "azurerm_network_security_rule" "allow_all_egress" {
  for_each                    = azurerm_subnet.hub
  name                        = "hub_${each.key}_allow_all_egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.hub[each.key].name
}

# allow all inbound rule for hub nsgs
resource "azurerm_network_security_rule" "allow_all_ingress" {
  for_each                    = azurerm_subnet.hub
  name                        = "hub_${each.key}_allow_all_ingress"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.hub[each.key].name
}

resource "azurerm_network_security_group" "spokes" {
  for_each            = { for k, v in azurerm_virtual_network.trace : k => v if k != "hub" }
  name                = "${var.network_name}_${each.key}_nsg"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

resource "azurerm_network_security_rule" "spokes_to_hub" {
  for_each                    = { for k, v in azurerm_virtual_network.trace : k => v if k != "hub" }
  name                        = "${each.key}_to_hub_outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace[each.key].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["hub"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes[each.key].name
}

resource "azurerm_network_security_rule" "dmz_outbound_to_app" {
  name                        = "dmz_out_to_app"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace["dmz"].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["app"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes["dmz"].name
}

resource "azurerm_network_security_rule" "dmz_inbound_from_app" {
  name                        = "dmz_in_from_app"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace["app"].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["dmz"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes["dmz"].name
}

resource "azurerm_network_security_rule" "app_outbound_to_db" {
  name                        = "app_out_to_db"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace["app"].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["db"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes["app"].name
}

resource "azurerm_network_security_rule" "app_inbound_from_db" {
  name                        = "app_in_from_db"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace["db"].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["app"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes["app"].name
}

resource "azurerm_network_security_rule" "db_outbound_to_app" {
  name                        = "db_out_to_app"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace["db"].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["app"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes["db"].name
}

resource "azurerm_network_security_rule" "db_inbound_from_app" {
  name                        = "db_in_from_app"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = element(azurerm_virtual_network.trace["app"].address_space, 0)
  destination_address_prefix  = element(azurerm_virtual_network.trace["db"].address_space, 0)
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes["db"].name
}

resource "azurerm_network_security_rule" "default_deny_all_in" {
  for_each                    = { for k, v in azurerm_virtual_network.trace : k => v if k != "hub" }
  name                        = "default_deny_all_in"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.spokes[each.key].name
}

# creates separate resource group for network watcher and flow logs
resource "azurerm_resource_group" "logging" {
  name     = "trace-logging-rg"
  location = "East US"
}

#network watcher service
resource "azurerm_network_watcher" "trace" {
  name                = "${var.network_name}-net-watcher"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
}

# builds storage account to store flow logs
resource "azurerm_storage_account" "flow_logs" {
  name                     = "flowlogstoragetrace10420"
  resource_group_name      = azurerm_resource_group.logging.name
  location                 = azurerm_resource_group.logging.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

/* # builds a flow log for each network security group
resource "azurerm_network_watcher_flow_log" "trace" {
  for_each             = azurerm_network_security_group.spokes
  network_watcher_name = azurerm_network_watcher.trace.name
  resource_group_name  = azurerm_resource_group.logging.name
  name                 = "trace-flow-log"

  network_security_group_id = azurerm_network_security_group.spokes[each.key].id
  storage_account_id        = azurerm_storage_account.flow_logs.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

}  */