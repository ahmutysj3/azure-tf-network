data "azurerm_resource_group" "tf_lab" {
  name = "terraform_lab"
}

resource "azurerm_virtual_network" "security" {
  name                = "${var.network_name}_security_vnet"
  location            = data.azurerm_resource_group.tf_lab.location
  resource_group_name = data.azurerm_resource_group.tf_lab.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    type = "hub"
  }
}

resource "azurerm_virtual_network" "spoke_1" {
  name                = "${var.network_name}_spoke_1_vnet"
  location            = data.azurerm_resource_group.tf_lab.location
  resource_group_name = data.azurerm_resource_group.tf_lab.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    type = "spoke"
  }
}

resource "azurerm_virtual_network" "spoke_2" {
  name                = "${var.network_name}_spoke_2_vnet"
  location            = data.azurerm_resource_group.tf_lab.location
  resource_group_name = data.azurerm_resource_group.tf_lab.name
  address_space       = ["10.2.0.0/16"]

  tags = {
    type = "spoke"
  }
}