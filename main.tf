
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

resource "azurerm_virtual_network_peering" "hub" {
  for_each = {for k, v in azurerm_virtual_network.trace : k => v.id if k != "hub"}
  name                      = "vnet_peering_hub_to_${each.key}"
  resource_group_name       = azurerm_resource_group.trace.name
  virtual_network_name      = azurerm_virtual_network.trace["hub"].name
  remote_virtual_network_id = each.value
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "spokes" {
  for_each = {for k, v in azurerm_virtual_network.trace : k => v.name if k != "hub"}
  name                      = "vnet_peering_${each.key}_to_hub"
  resource_group_name       = azurerm_resource_group.trace.name
  virtual_network_name      = each.value
  remote_virtual_network_id = azurerm_virtual_network.trace["hub"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit = false
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

resource "azurerm_route_table" "inside" {
  name                = "hub_inside_rt"
  location            = azurerm_resource_group.trace.location
  resource_group_name = azurerm_resource_group.trace.name
}

resource "azurerm_route" "spokes" {
  for_each = {for k, v in azurerm_virtual_network.trace : k => v.address_space if k != "hub"}
  name                = "route_to_${each.key}"
  resource_group_name = azurerm_resource_group.trace.name
  route_table_name    = azurerm_route_table.inside.name
  address_prefix      = element(each.value,0)
  next_hop_type       = "VnetLocal"
}

# creates a spoke subnet for each entry in var.subnet_params and assigns to vnet listed in "vnet" argument
resource "azurerm_subnet" "spoke" {
  for_each = var.subnet_params
  name                 = "${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.trace.name
  virtual_network_name = azurerm_virtual_network.trace["${each.value.vnet}"].name
  address_prefixes     = [each.value.cidr]
}