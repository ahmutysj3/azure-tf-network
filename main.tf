
resource "azurerm_resource_group" "trace" {
  name     = "trace-resource-group"
  location = "East US"
}

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
    environment = "Trace-AZ-Lab"
  }
}

resource "azurerm_subnet" "hub" {
  for_each = {
    "outside" = cidrsubnet(element(azurerm_virtual_network.trace["hub"].address_space,0),9,0)
    "inside" = cidrsubnet(element(azurerm_virtual_network.trace["hub"].address_space,0),9,1)
  }
  name = "hub_${each.key}_subnet"
  resource_group_name = azurerm_resource_group.trace.name
  virtual_network_name = azurerm_virtual_network.trace["hub"].name
  address_prefixes = [each.value]

  tags = {
    environment = "Trace-AZ-Lab"
  }
}

resource "azurerm_subnet" "spoke" {
  for_each = var.subnet_params
  name                 = "${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.trace.name
  virtual_network_name = azurerm_virtual_network.trace["${each.value.vnet}"].name
  address_prefixes     = [each.value.cidr]
}