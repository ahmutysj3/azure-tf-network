
resource "azurerm_virtual_network" "trace" {
  name                = "trace-network"
  location            = azurerm_resource_group.trace.location
  resource_group_name = azurerm_resource_group.trace.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.trace.id
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "trace" {
  name                = "trace-security-group"
  location            = azurerm_resource_group.trace.location
  resource_group_name = azurerm_resource_group.trace.name
}


resource "azurerm_resource_group" "trace" {
  name     = "trace-resource-group"
  location = "East US"
}