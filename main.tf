
resource "azurerm_resource_group" "trace" {
  name     = "trace-resource-group"
  location = "East US"
}

resource "azurerm_virtual_network" "trace" {
  for_each = {
    "hub" = "10.1.0.0/16"
    "dmz" = "10.2.0.0/16"
    "app" = "10.3.0.0/16"
    "db" = "10.4.0.0/16"
  }

  name                = "${var.network_name}_${each.key}_vnet"
  location            = azurerm_resource_group.trace.location
  resource_group_name = azurerm_resource_group.trace.name
  address_space       = [each.value]

  tags = {
    environment = "Trace-AZ-Lab"
  }
}

resource "azurerm_subnet" "trace" {
  for_each = var.subnet_params
  name                 = "${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.trace.name
  virtual_network_name = azurerm_virtual_network.trace["${each.value.vnet}"].name
  address_prefixes     = [each.value.cidr]
}