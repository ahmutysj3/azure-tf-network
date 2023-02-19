
resource "azurerm_resource_group" "trace" {
  name     = "trace-resource-group"
  location = "East US"
}


# Builds 4 conseq. /16 vnets
resource "azurerm_virtual_network" "trace" {
  for_each = {
    "hub" = 1
    "dmz" = 2
    "app" = 3
    "db" = 4
  }

  name                = "${var.network_name}_${each.key}_vnet"
  location            = azurerm_resource_group.trace.location
  resource_group_name = azurerm_resource_group.trace.name
  address_space       = [cidrsubnet("${var.supernet}",8,each.value)]

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

resource "azurerm_virtual_network_peering" "hub_dmz" {
  name                      = "vnet_peering_hub_to_dmz"
  resource_group_name       = azurerm_resource_group.trace.name
  virtual_network_name      = azurerm_virtual_network.trace["hub"].name
  remote_virtual_network_id = azurerm_virtual_network.trace["dmz"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "dmz_hub" {
  name                      = "vnet_peering_dmz_to_hub"
  resource_group_name       = azurerm_resource_group.trace.name
  virtual_network_name      = azurerm_virtual_network.trace["dmz"].name
  remote_virtual_network_id = azurerm_virtual_network.trace["hub"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# creates 2 x /25 subnets for inside and outside fw interfaces
resource "azurerm_subnet" "hub" {
  for_each = {
    "outside" = cidrsubnet(element(azurerm_virtual_network.trace["hub"].address_space,0),9,0)
    "inside" = cidrsubnet(element(azurerm_virtual_network.trace["hub"].address_space,0),9,1)
  }
  name = "hub_${each.key}_subnet"
  resource_group_name = azurerm_resource_group.trace.name
  virtual_network_name = azurerm_virtual_network.trace["hub"].name
  address_prefixes = [each.value]
}

resource "azurerm_route_table" "outside" {
  name                          = "hub_outside_rt"
  location                      = azurerm_resource_group.trace.location
  resource_group_name           = azurerm_resource_group.trace.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = {
    environment = "Trace_AZ_Lab"
  }
}

# creates a spoke subnet for each entry in var.subnet_params and assigns to vnet listed in "vnet" argument
resource "azurerm_subnet" "spoke" {
  for_each = var.subnet_params
  name                 = "${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.trace.name
  virtual_network_name = azurerm_virtual_network.trace["${each.value.vnet}"].name
  address_prefixes     = [each.value.cidr]
}